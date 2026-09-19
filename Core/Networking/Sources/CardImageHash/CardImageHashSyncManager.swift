import Foundation
@preconcurrency import Vision
import CoreImage
import Accelerate // Hardware-accelerated vector math
import ComposableArchitecture

public protocol CardImageHashSyncManagable: Sendable {
  func sync() async
  func findBestMatches(for image: CGImage) async -> [MatchResult]
}

public struct MatchResult: Sendable, Equatable {
  public let id: String
  public let distance: Float
  
  public init(id: String, distance: Float) {
    self.id = id
    self.distance = distance
  }
}

public enum SyncError: Error, LocalizedError {
  case invalidURL
  case manifestFetchFailed
  case databaseFetchFailed
  case decompressionFailed
  case decodeFailed
  
  public var errorDescription: String? {
    switch self {
    case .invalidURL: return "The cloud URL is invalid."
    case .manifestFetchFailed: return "Could not fetch the latest version info."
    case .databaseFetchFailed: return "Failed to download the database file."
    case .decompressionFailed: return "Failed to decompress the LZFSE data."
    case .decodeFailed: return "Failed to decode the binary plist."
    }
  }
}

// Lightweight model holding raw contiguous memory instead of heavy Vision objects
private struct DatabaseItem: @unchecked Sendable {
  let id: String
  let vector: [Float]
}

public final actor CardImageHashSyncManager: CardImageHashSyncManagable {
  public typealias DataLoader = @Sendable (URL) async throws -> (Data, URLResponse)

  // Contiguous array for extremely fast parallel iteration and caching
  private var searchDatabase: [DatabaseItem] = []
  
  public var isReady = false
  public var syncStatus = "Initializing..." {
    didSet {
      print(syncStatus)
    }
  }
  public var isDownloading = false
  
  private let baseURL: String
  private let defaults: UserDefaults
  private let loadData: DataLoader
  private let documentsDirectory: URL
  
  private var localDatabaseURL: URL {
    documentsDirectory.appendingPathComponent("MTG_Hashes_Compressed.lzfse")
  }
  
  private var localManifestURL: URL {
    documentsDirectory.appendingPathComponent("manifest.json")
  }
  
  func generateFeaturePrint(from cgImage: CGImage) throws -> VNFeaturePrintObservation? {
    let request = VNGenerateImageFeaturePrintRequest()
    
    // Revision2 is the floor everywhere at our deployment target, and the
    // stored database is built with it, so there is nothing to branch on.
    request.revision = VNGenerateImageFeaturePrintRequestRevision2
    request.imageCropAndScaleOption = .scaleFill

    try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
    return request.results?.first as? VNFeaturePrintObservation
  }
  
  public init(
    baseURL: String = "https://missingems.github.io/MTGImageHash",
    defaults: UserDefaults = .standard,
    documentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
    loadData: @escaping DataLoader = { try await URLSession.shared.data(from: $0) }
  ) {
    self.baseURL = baseURL
    self.defaults = defaults
    self.documentsDirectory = documentsDirectory
    self.loadData = loadData
  }
  
  public func sync() async {
    await loadLocalCache()
    await syncFromGitHub()
  }
  
  // MARK: - Core Search Engine (Accelerate + TaskGroup + Dynamic Threshold)
  
  public func findBestMatches(for image: CGImage) async -> [MatchResult] {
#if targetEnvironment(simulator)
    return [MatchResult(id: "57950af0-92d8-467e-9124-2206c84228c8", distance: 0)]
#else
    guard let targetObservation = try? generateFeaturePrint(from: image) else {
      return []
    }

    // 1. Extract raw floats from target image exactly ONCE
    let elementCount = targetObservation.elementCount
    let targetVector = [Float](unsafeUninitializedCapacity: elementCount) { buffer, initializedCount in
      _ = targetObservation.data.copyBytes(to: buffer)
      initializedCount = elementCount
    }
    
    let searchDatabase = self.searchDatabase
    let totalCards = searchDatabase.count
    guard totalCards > 0 else { return [] }
    
    // Since we removed sqrt() for speed, we compare against the squared threshold.
    let initialSquaredThreshold: Float = 1.0
    
    // 2. Dynamically chunk the array based on available CPU cores
    let coreCount = ProcessInfo.processInfo.activeProcessorCount
    let chunkSize = max(2000, totalCards / coreCount)
    
    // 3. MapReduce parallel search
    return await withTaskGroup(of: [MatchResult].self) { group in
      for startIndex in stride(from: 0, to: totalCards, by: chunkSize) {
        let endIndex = min(startIndex + chunkSize, totalCards)
        
        // Pass a memory slice (zero-cost) to the background thread
        let chunk = searchDatabase[startIndex..<endIndex]
        
        group.addTask {
          var localTop5: [MatchResult] = []
          localTop5.reserveCapacity(6) // Only need space for 5 + 1 temp
          
          var dynamicThreshold = initialSquaredThreshold
          
          for item in chunk {
            var squaredDistance: Float = 0
            
            // 🚀 vDSP calculates the difference of 2048 floats at silicon speed
            vDSP_distancesq(
              targetVector, 1,
              item.vector, 1,
              &squaredDistance,
              vDSP_Length(elementCount)
            )
            
            // 🛑 THE DYNAMIC GATE: Only proceed if it beats the current worst match
            if squaredDistance < dynamicThreshold {
              localTop5.append(MatchResult(id: item.id, distance: squaredDistance))
              
              // Keep the tiny array sorted so the worst match is always at the end
              localTop5.sort { $0.distance < $1.distance }
              
              // If we have 6 items, kick out the worst one
              if localTop5.count > 5 {
                localTop5.removeLast()
              }
              
              // If we have a full top 5, the 5th place distance becomes the new threshold!
              if localTop5.count == 5 {
                dynamicThreshold = localTop5.last!.distance
              }
            }
          }
          
          return localTop5
        }
      }
      
      // 4. Merge the top 5 results from all threads
      var globalCandidates: [MatchResult] = []
      globalCandidates.reserveCapacity(coreCount * 5)
      
      for await chunkTop5 in group {
        globalCandidates.append(contentsOf: chunkTop5)
      }
      
      globalCandidates.sort { $0.distance < $1.distance }
      return globalCandidates.prefix(5).map {
        MatchResult(id: $0.id, distance: $0.distance)
      }
    }
#endif
  }
  
  // MARK: - Hydration & Sync

  /// Decodes a `[faceId: archived VNFeaturePrintObservation]` dictionary straight
  /// into the flat search array, without keeping the observations around.
  private nonisolated static func searchItems(from dictionary: [String: Data]) -> [DatabaseItem] {
    dictionary.compactMap { id, vectorData in
      guard let observation = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: VNFeaturePrintObservation.self,
        from: vectorData
      ) else { return nil }
      let count = observation.elementCount
      let vector = [Float](unsafeUninitializedCapacity: count) { buffer, initializedCount in
        _ = observation.data.copyBytes(to: buffer)
        initializedCount = count
      }
      return DatabaseItem(id: id, vector: vector)
    }
  }

  private nonisolated static func decodeDatabase(_ data: Data) throws -> [String: Data] {
    let decompressed = (try? (data as NSData).decompressed(using: .lzfse) as Data) ?? data
    guard let dictionary = try PropertyListSerialization.propertyList(
      from: decompressed,
      options: [],
      format: nil
    ) as? [String: Data] else {
      throw SyncError.decodeFailed
    }
    return dictionary
  }

  private func loadLocalCache() async {
    let dbURL = localDatabaseURL
    let fileManager = FileManager.default

    if !fileManager.fileExists(atPath: dbURL.path) {
      self.syncStatus = "First launch: Unpacking embedded database..."

      let frameworkBundle = Bundle(for: BundleFinder.self)
      let resourceBundle = frameworkBundle.urls(forResourcesWithExtension: "bundle", subdirectory: nil)?
        .first
        .flatMap(Bundle.init(url:))
      func bundled(_ name: String, _ ext: String) -> URL? {
        frameworkBundle.url(forResource: name, withExtension: ext)
          ?? resourceBundle?.url(forResource: name, withExtension: ext)
      }

      guard let bundleDBPath = bundled("MTG_Hashes_Compressed", "lzfse") else {
        self.syncStatus = "Error: Missing MTG_Hashes_Compressed.lzfse in module resources."
        return
      }

      do {
        try fileManager.copyItem(at: bundleDBPath, to: dbURL)
        // Ship MTG_Hashes_Manifest.json (the server's manifest.json for the same
        // master) alongside the bundled database, and fresh installs only fetch
        // patches. Without it the first sync downloads the full master.
        if let bundleManifestPath = bundled("MTG_Hashes_Manifest", "json"),
           !fileManager.fileExists(atPath: localManifestURL.path) {
          try fileManager.copyItem(at: bundleManifestPath, to: localManifestURL)
        }
      } catch {
        self.syncStatus = "Failed to unpack database: \(error.localizedDescription)"
        return
      }
    }

    self.syncStatus = "Loading local database..."

    do {
      let items = try await Task.detached {
        try Self.searchItems(from: Self.decodeDatabase(Data(contentsOf: dbURL)))
      }.value

      self.searchDatabase = items
      self.isReady = true
      self.syncStatus = "Loaded \(items.count) cards locally."
    } catch {
      self.syncStatus = "Failed to load local cache. Corrupted file."
    }
  }

  private func syncFromGitHub() async {
    guard let baseURL = URL(string: baseURL) else { return }

    self.isDownloading = true
    defer { self.isDownloading = false }

    do {
      let remoteManifestData = try await download(baseURL.appendingPathComponent("manifest.json"), or: .manifestFetchFailed)
      let remoteManifest = try JSONDecoder().decode(CardHashDatabaseManifest.self, from: remoteManifestData)

      // -1 means "download the full master": no local manifest (so we can't tell
      // which master the local database belongs to), or a different master.
      var localPatchLevel = -1
      if let localManifestData = try? Data(contentsOf: localManifestURL),
         let localManifest = try? JSONDecoder().decode(CardHashDatabaseManifest.self, from: localManifestData),
         localManifest.masterVersion == remoteManifest.masterVersion {
        localPatchLevel = localManifest.latestPatch
      }

      guard remoteManifest.latestPatch > localPatchLevel else {
        self.syncStatus = "Database is up to date."
        return
      }

      let updatedDictionary: [String: Data]
      if localPatchLevel == -1 || remoteManifest.latestPatch - localPatchLevel > 20 {
        self.syncStatus = "Downloading database..."
        updatedDictionary = try await downloadMaster(remoteManifest, baseURL: baseURL)
      } else {
        self.syncStatus = "Downloading \(remoteManifest.latestPatch - localPatchLevel) update(s)..."
        updatedDictionary = try await downloadAndMergePatches(
          from: localPatchLevel + 1,
          through: remoteManifest.latestPatch,
          baseURL: baseURL
        )
      }

      self.syncStatus = "Hydrating updated vectors..."
      let databaseURL = localDatabaseURL, manifestURL = localManifestURL
      let items = try await Task.detached {
        let binary = try PropertyListSerialization.data(fromPropertyList: updatedDictionary, format: .binary, options: 0)
        let compressed = try (binary as NSData).compressed(using: .lzfse) as Data
        // Database before manifest: a crash in between leaves an old manifest, which
        // only means re-applying patches next time.
        try compressed.write(to: databaseURL, options: .atomic)
        try remoteManifestData.write(to: manifestURL, options: .atomic)
        return Self.searchItems(from: updatedDictionary)
      }.value

      self.searchDatabase = items
      self.isReady = true
      self.syncStatus = "Up to date (\(items.count) cards)."
    } catch {
      // The local database is untouched on any failure; the next sync retries.
      self.syncStatus = "Failed to sync: \(error.localizedDescription)"
    }
  }

  // MARK: - Download Helpers

  private func download(_ url: URL, or failure: SyncError) async throws -> Data {
    let (data, response) = try await loadData(url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw failure }
    return data
  }

  /// Every chunk the manifest lists must arrive; a partial master is never saved.
  private func downloadMaster(_ manifest: CardHashDatabaseManifest, baseURL: URL) async throws -> [String: Data] {
    guard manifest.masterChunks > 0 else { throw SyncError.databaseFetchFailed }
    var masterDictionary: [String: Data] = [:]
    for index in 0..<manifest.masterChunks {
      let chunk = try await download(
        baseURL.appendingPathComponent("MTG_Hashes_Master_\(index).lzfse"),
        or: .databaseFetchFailed
      )
      let chunkDictionary = try await Task.detached { try Self.decodeDatabase(chunk) }.value
      masterDictionary.merge(chunkDictionary) { _, new in new }
    }
    guard !masterDictionary.isEmpty else { throw SyncError.decodeFailed }
    return masterDictionary
  }

  /// Applies patches in order. Any missing patch aborts the sync, so the saved
  /// patch level never claims updates the database doesn't contain.
  private func downloadAndMergePatches(from first: Int, through last: Int, baseURL: URL) async throws -> [String: Data] {
    var patches: [Data] = []
    for patchNumber in first...last {
      patches.append(try await download(
        baseURL.appendingPathComponent("patch_\(patchNumber).lzfse"),
        or: .databaseFetchFailed
      ))
    }
    let databaseURL = localDatabaseURL
    return try await Task.detached {
      var masterDictionary = try Self.decodeDatabase(Data(contentsOf: databaseURL))
      for patch in patches {
        masterDictionary.merge(try Self.decodeDatabase(patch)) { _, new in new }
      }
      return masterDictionary
    }.value
  }
}

public extension DependencyValues {
  var cardImageHashSyncManager: any CardImageHashSyncManagable {
    get { self[CardImageHashSyncManagerKey.self] }
    set { self[CardImageHashSyncManagerKey.self] = newValue }
  }
}

public enum CardImageHashSyncManagerKey: DependencyKey {
  public static let liveValue: any CardImageHashSyncManagable = CardImageHashSyncManager()
  public static let previewValue: any CardImageHashSyncManagable = CardImageHashSyncManager()
  public static let testValue: any CardImageHashSyncManagable = CardImageHashSyncManager()
}

private class BundleFinder {}
