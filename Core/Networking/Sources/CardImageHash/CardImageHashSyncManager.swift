import Foundation
@preconcurrency import Vision
import CoreImage
import Accelerate
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

public final actor CardImageHashSyncManager: CardImageHashSyncManagable {
  
  var observations: [String: VNFeaturePrintObservation] = [:]
  
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
  
  public func findBestMatches(for image: CGImage) -> [MatchResult] {
    guard let targetObservation = try? generateFeaturePrint(from: image) else {
      return []
    }
    var candidates: [MatchResult] = []
    let confidenceThreshold: Float = 1.0
    
    for (id, dbObservation) in observations {
      var distance: Float = 0
      do {
        try targetObservation.computeDistance(&distance, to: dbObservation)
        if distance <= confidenceThreshold {
          candidates.append(MatchResult(id: id, distance: distance))
        }
      } catch {
        continue
      }
    }
    
#if targetEnvironment(simulator)
    return [MatchResult(id: "57950af0-92d8-467e-9124-2206c84228c8", distance: 0)]
#endif
    
    return candidates
      .sorted { $0.distance < $1.distance }
      .prefix(5)
      .map { $0 }
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
      // 1. Fetch Remote Manifest
      let (remoteManifestData, _) = try await URLSession.shared.data(from: manifestURL)
      
      let remoteManifest = try JSONDecoder().decode(CardHashDatabaseManifest.self, from: remoteManifestData)
      
      // 2. Read Local Manifest State
      var localPatchLevel = 0
      if let localManifestData = try? Data(contentsOf: localManifestURL),
         let localManifest = try? JSONDecoder().decode(CardHashDatabaseManifest.self, from: localManifestData) {
        localPatchLevel = localManifest.latestPatch
        
        // If the remote master version is completely different, force a full reset
        if localManifest.masterVersion != remoteManifest.masterVersion {
          localPatchLevel = -1
        }
      }
      
      // 3. Check if we need updates
      guard remoteManifest.latestPatch > localPatchLevel else {
        self.syncStatus = "Database is up to date."
        return
      }
      
      let patchGap = remoteManifest.latestPatch - localPatchLevel
      
      // 4. Threshold Logic: Delta Patch vs Chunked Master
      let updatedDictionary = try await Task.detached {
        var newMasterDict: [String: Data] = [:]
        
        if patchGap > 20 || localPatchLevel == -1 {
          // Fallback: Download the stitched chunks if we are too far behind
          newMasterDict = try await self.downloadChunkedMaster(remoteManifest: remoteManifest)
        } else {
          // Standard: Download missing sequential patches
          newMasterDict = try await self.downloadAndMergePatches(localVersion: localPatchLevel, remoteVersion: remoteManifest.latestPatch)
        }
        
        // Re-compress and save the newly assembled master database
        let updatedBinary = try PropertyListSerialization.data(fromPropertyList: newMasterDict, format: .binary, options: 0)
        let updatedCompressed = try (updatedBinary as NSData).compressed(using: .lzfse) as Data
        try await updatedCompressed.write(to: self.localDatabaseURL)
        
        // Save the remote manifest locally so we know we are synced
        try await remoteManifestData.write(to: self.localManifestURL)
        
        return newMasterDict
      }.value
      
      // 5. Hydrate the updated dictionary into RAM
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
      self.syncStatus = "Up to date (\(hydratedDict.count) cards)."
      
    } catch {
      if !self.isReady {
        self.syncStatus = "Failed to sync: Check internet connection."
      }
    }
  }
  
  // MARK: - Download Helpers (Runs in Detached Tasks)
  
  private nonisolated func downloadChunkedMaster(remoteManifest: CardHashDatabaseManifest) async throws -> [String: Data] {
    var masterDictionary: [String: Data] = [:]
    masterDictionary.reserveCapacity(90000)
    
    for i in 0..<remoteManifest.masterChunks {
      let chunkURL = URL(string: "\(baseURL)/MTG_Hashes_Master_\(i).lzfse")!
      
      if let (compressedData, response) = try? await URLSession.shared.data(from: chunkURL),
         let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        
        let decompressedData = try (compressedData as NSData).decompressed(using: .lzfse) as Data
        if let chunkDict = try PropertyListSerialization.propertyList(from: decompressedData, options: [], format: nil) as? [String: Data] {
          masterDictionary.merge(chunkDict) { (current, _) in current }
        }
      } else {
        throw SyncError.databaseFetchFailed
      }
    }
    return masterDictionary
  }
  
  private nonisolated func downloadAndMergePatches(localVersion: Int, remoteVersion: Int) async throws -> [String: Data] {
    // 1. Load current master into RAM
    let localCompressed = try await Data(contentsOf: self.localDatabaseURL)
    let localDecompressed = (try? (localCompressed as NSData).decompressed(using: .lzfse) as Data) ?? localCompressed
    guard var masterDictionary = try PropertyListSerialization.propertyList(from: localDecompressed, options: [], format: nil) as? [String: Data] else {
      throw SyncError.decodeFailed
    }
    
    // 2. Download missing sequential patches
    for patchNumber in (localVersion + 1)...remoteVersion {
      let patchURL = URL(string: "\(baseURL)/patch_\(patchNumber).lzfse")!
      
      if let (patchCompressed, response) = try? await URLSession.shared.data(from: patchURL),
         let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        
        let patchDecompressed = try (patchCompressed as NSData).decompressed(using: .lzfse) as Data
        if let patchDict = try PropertyListSerialization.propertyList(from: patchDecompressed, options: [], format: nil) as? [String: Data] {
          // Merge new vectors (overwrites if ID already exists)
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
