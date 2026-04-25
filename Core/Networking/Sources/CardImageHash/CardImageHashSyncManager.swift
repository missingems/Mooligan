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
  
  var observations: [String: VNFeaturePrintObservation] = [:]
  
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
  
  private var documentsDirectory: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }
  
  private var localDatabaseURL: URL {
    documentsDirectory.appendingPathComponent("MTG_Hashes_Compressed.lzfse")
  }
  
  private var localManifestURL: URL {
    documentsDirectory.appendingPathComponent("manifest.json")
  }
  
  func generateFeaturePrint(from cgImage: CGImage) throws -> VNFeaturePrintObservation? {
    let request = VNGenerateImageFeaturePrintRequest()
    
    if let dbModel = observations.values.first {
      request.revision = VNGenerateImageFeaturePrintRequestRevision2
    } else {
      if #available(iOS 17.0, macOS 14.0, *) {
        request.revision = VNGenerateImageFeaturePrintRequestRevision2
      } else {
        request.revision = VNGenerateImageFeaturePrintRequestRevision1
      }
    }
    
    request.imageCropAndScaleOption = .scaleFill
    
#if targetEnvironment(simulator)
    request.usesCPUOnly = true
#endif
    
    try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
    return request.results?.first as? VNFeaturePrintObservation
  }
  
  public init(
    baseURL: String = "https://missingems.github.io/MTGImageHash",
    defaults: UserDefaults = .standard
  ) {
    self.baseURL = baseURL
    self.defaults = defaults
  }
  
  public func sync() async {
    await loadLocalCache()
    await syncFromGitHub()
  }
  
  // MARK: - Core Search Engine (Accelerate + TaskGroup + Dynamic Threshold)
  
  public func findBestMatches(for image: CGImage) async -> [MatchResult] {
    guard let targetObservation = try? generateFeaturePrint(from: image) else {
      return []
    }
    
#if targetEnvironment(simulator)
    return [MatchResult(id: "57950af0-92d8-467e-9124-2206c84228c8", distance: 0)]
#endif
    
    // 1. Extract raw floats from target image exactly ONCE
    let elementCount = targetObservation.elementCount
    let targetVector = [Float](unsafeUninitializedCapacity: elementCount) { buffer, initializedCount in
      targetObservation.data.copyBytes(to: buffer)
      initializedCount = elementCount
    }
    
    let db = self.searchDatabase
    let totalCards = db.count
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
        let chunk = db[startIndex..<endIndex]
        
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
  }
  
  // MARK: - Hydration & Sync
  
  private func hydrateSearchDatabase(from dictionary: [String: VNFeaturePrintObservation]) {
    self.searchDatabase = dictionary.compactMap { id, obs in
      let count = obs.elementCount
      let vector = [Float](unsafeUninitializedCapacity: count) { buffer, initializedCount in
        obs.data.copyBytes(to: buffer)
        initializedCount = count
      }
      return DatabaseItem(id: id, vector: vector)
    }
  }
  
  private func loadLocalCache() async {
    let dbURL = localDatabaseURL
    let fileManager = FileManager.default
    
    if !fileManager.fileExists(atPath: dbURL.path) {
      self.syncStatus = "First launch: Unpacking embedded database..."
      
      let frameworkBundle = Bundle(for: BundleFinder.self)
      var targetDBPath: URL? = nil
      var targetManifestPath: URL? = nil
      
      if let rootURL = frameworkBundle.url(forResource: "MTG_Hashes_Compressed", withExtension: "lzfse") {
        targetDBPath = rootURL
      } else if let resourceBundleURL = frameworkBundle.urls(forResourcesWithExtension: "bundle", subdirectory: nil)?.first,
                let resourceBundle = Bundle(url: resourceBundleURL) {
        targetDBPath = resourceBundle.url(forResource: "MTG_Hashes_Compressed", withExtension: "lzfse")
      }
      
      guard let bundleDBPath = targetDBPath else {
        self.syncStatus = "Error: Missing MTG_Hashes_Compressed.lzfse in module resources."
        return
      }
      
      do {
        try fileManager.copyItem(at: bundleDBPath, to: dbURL)
        if let bundleManifestPath = targetManifestPath {
          if !fileManager.fileExists(atPath: localManifestURL.path) {
            try fileManager.copyItem(at: bundleManifestPath, to: localManifestURL)
          }
        }
      } catch {
        self.syncStatus = "Failed to unpack database: \(error.localizedDescription)"
        return
      }
    }
    
    self.syncStatus = "Loading local database..."
    
    do {
      let hydratedDict = try await Task.detached {
        let fileData = try Data(contentsOf: dbURL)
        let decompressedData = (try? (fileData as NSData).decompressed(using: .lzfse) as Data) ?? fileData
        
        guard let flatDict = try PropertyListSerialization.propertyList(from: decompressedData, options: [], format: nil) as? [String: Data] else {
          throw SyncError.decodeFailed
        }
        
        var activeObservations: [String: VNFeaturePrintObservation] = [:]
        activeObservations.reserveCapacity(flatDict.count)
        
        for (id, vectorData) in flatDict {
          if let obs = try? NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: vectorData) {
            activeObservations[id] = obs
          }
        }
        return activeObservations
      }.value
      
      self.observations = hydratedDict
      self.hydrateSearchDatabase(from: hydratedDict) // Build the fast search array
      
      self.isReady = true
      self.syncStatus = "Loaded \(hydratedDict.count) cards locally."
      
    } catch {
      self.syncStatus = "Failed to load local cache. Corrupted file."
    }
  }
  
  private func syncFromGitHub() async {
    guard let manifestURL = URL(string: "\(baseURL)/manifest.json") else { return }
    
    self.isDownloading = true
    defer { self.isDownloading = false }
    
    do {
      let (remoteManifestData, _) = try await URLSession.shared.data(from: manifestURL)
      
      struct CardHashDatabaseManifest: Decodable {
        let masterVersion: String
        let latestPatch: Int
        let masterChunks: Int
      }
      
      let remoteManifest = try JSONDecoder().decode(CardHashDatabaseManifest.self, from: remoteManifestData)
      
      var localPatchLevel = 0
      if let localManifestData = try? Data(contentsOf: localManifestURL),
         let localManifest = try? JSONDecoder().decode(CardHashDatabaseManifest.self, from: localManifestData) {
        localPatchLevel = localManifest.latestPatch
        
        if localManifest.masterVersion != remoteManifest.masterVersion {
          localPatchLevel = -1
        }
      }
      
      guard remoteManifest.latestPatch > localPatchLevel else {
        self.syncStatus = "Database is up to date."
        return
      }
      
      let patchGap = remoteManifest.latestPatch - localPatchLevel
      
      let updatedDictionary = try await Task.detached {
        var newMasterDict: [String: Data] = [:]
        
        if patchGap > 20 || localPatchLevel == -1 {
          newMasterDict = try await self.downloadChunkedMaster(remoteManifest: remoteManifest, baseURL: self.baseURL)
        } else {
          newMasterDict = try await self.downloadAndMergePatches(localVersion: localPatchLevel, remoteVersion: remoteManifest.latestPatch, baseURL: self.baseURL, localDatabaseURL: self.localDatabaseURL)
        }
        
        let updatedBinary = try PropertyListSerialization.data(fromPropertyList: newMasterDict, format: .binary, options: 0)
        let updatedCompressed = try (updatedBinary as NSData).compressed(using: .lzfse) as Data
        try await updatedCompressed.write(to: self.localDatabaseURL)
        
        try await remoteManifestData.write(to: self.localManifestURL)
        
        return newMasterDict
      }.value
      
      self.syncStatus = "Hydrating updated vectors..."
      
      let hydratedDict = await Task.detached {
        var activeObservations: [String: VNFeaturePrintObservation] = [:]
        activeObservations.reserveCapacity(updatedDictionary.count)
        for (id, vectorData) in updatedDictionary {
          if let obs = try? NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: vectorData) {
            activeObservations[id] = obs
          }
        }
        return activeObservations
      }.value
      
      self.observations = hydratedDict
      self.hydrateSearchDatabase(from: hydratedDict) // Rebuild the fast search array
      self.syncStatus = "Up to date (\(hydratedDict.count) cards)."
      
    } catch {
      if !self.isReady {
        self.syncStatus = "Failed to sync: Check internet connection."
      }
    }
  }
  
  // MARK: - Download Helpers
  
  private nonisolated func downloadChunkedMaster(remoteManifest: Any, baseURL: String) async throws -> [String: Data] {
    var masterDictionary: [String: Data] = [:]
    masterDictionary.reserveCapacity(90000)
    
    // Adjust maximum chunk attempts based on your actual manifest design
    for i in 0..<10 {
      let chunkURL = URL(string: "\(baseURL)/MTG_Hashes_Master_\(i).lzfse")!
      
      if let (compressedData, response) = try? await URLSession.shared.data(from: chunkURL),
         let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        
        let decompressedData = try (compressedData as NSData).decompressed(using: .lzfse) as Data
        if let chunkDict = try PropertyListSerialization.propertyList(from: decompressedData, options: [], format: nil) as? [String: Data] {
          masterDictionary.merge(chunkDict) { (current, _) in current }
        }
      } else {
        break
      }
    }
    return masterDictionary
  }
  
  private nonisolated func downloadAndMergePatches(localVersion: Int, remoteVersion: Int, baseURL: String, localDatabaseURL: URL) async throws -> [String: Data] {
    let localCompressed = try Data(contentsOf: localDatabaseURL)
    let localDecompressed = (try? (localCompressed as NSData).decompressed(using: .lzfse) as Data) ?? localCompressed
    guard var masterDictionary = try PropertyListSerialization.propertyList(from: localDecompressed, options: [], format: nil) as? [String: Data] else {
      throw SyncError.decodeFailed
    }
    
    for patchNumber in (localVersion + 1)...remoteVersion {
      let patchURL = URL(string: "\(baseURL)/patch_\(patchNumber).lzfse")!
      
      if let (patchCompressed, response) = try? await URLSession.shared.data(from: patchURL),
         let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        
        let patchDecompressed = try (patchCompressed as NSData).decompressed(using: .lzfse) as Data
        if let patchDict = try PropertyListSerialization.propertyList(from: patchDecompressed, options: [], format: nil) as? [String: Data] {
          masterDictionary.merge(patchDict) { (_, new) in new }
        }
      }
    }
    return masterDictionary
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
