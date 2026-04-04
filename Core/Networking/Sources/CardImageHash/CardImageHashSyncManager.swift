import AVFoundation
import CoreImage
import Accelerate
import ComposableArchitecture
import Foundation
import UIKit

public protocol CardImageHashSyncManagable: Sendable {
  func sync() async
  func findBestMatch(for targetHash: UInt64) async -> MatchResult?
}

enum SyncError: Error, LocalizedError {
  case invalidURL
  case manifestFetchFailed
  case databaseFetchFailed
  case decompressionFailed
  case decodeFailed
  
  var errorDescription: String? {
    switch self {
    case .invalidURL: return "The GitHub URL is invalid."
    case .manifestFetchFailed: return "Could not fetch the latest version info."
    case .databaseFetchFailed: return "Failed to download the database file."
    case .decompressionFailed: return "Failed to decompress the LZFSE data."
    case .decodeFailed: return "Failed to decode the binary plist."
    }
  }
}

public final actor CardImageHashSyncManager: CardImageHashSyncManagable {
  var records: [CardImageHashRecord] = []
  var isReady = false
  var syncStatus = "Initializing..."
  var isDownloading = false
  
  private let baseURL = "https://missingems.github.io/MTGImageHash/"
  
  private var localDatabaseURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("MTG_Hashes.bplist")
  }
  
  public func sync() async {
    await loadLocalCache()
    await syncWithCloud()
  }
  
  public func findBestMatch(for targetHash: UInt64) -> MatchResult? {
    var bestMatchId: String?
    var lowestDistance = 64
    
    for record in records {
      let distance = (record.hash ^ targetHash).nonzeroBitCount
      
      if distance < lowestDistance {
        lowestDistance = distance
        bestMatchId = record.id
        
        if distance == 0 { break }
      }
    }
    
    if lowestDistance <= 20, let id = bestMatchId {
      return MatchResult(id: id, distance: lowestDistance)
    }
    
    return nil
  }
  
  private func loadLocalCache() async {
    let dbURL = localDatabaseURL
    
    do {
      let cachedRecords = try await Task.detached {
        let data = try Data(contentsOf: dbURL)
        return try PropertyListDecoder().decode([CardImageHashRecord].self, from: data)
      }.value
      
      self.records = cachedRecords
      self.isReady = true
      self.syncStatus = "Loaded \(cachedRecords.count) cards locally."
    } catch {
      self.syncStatus = "No local database. Waiting for cloud sync..."
    }
  }
  
  private func syncWithCloud() async {
    guard
      let manifestURL = URL(string: "\(baseURL)/manifest.json"),
      let databaseURL = URL(string: "\(baseURL)/MTG_Hashes.bplist")
    else {
      syncStatus = "Error: Invalid URLs"
      return
    }
    
    self.isDownloading = true
    defer { self.isDownloading = false }
    
    do {
      let (manifestData, _) = try await URLSession.shared.data(from: manifestURL)
      let remoteManifest = try JSONDecoder().decode(CardHashDatabaseManifest.self, from: manifestData)
      let localVersion = UserDefaults.standard.integer(forKey: "LocalDBVersion")
      
      if remoteManifest.version > localVersion || records.isEmpty {
        self.syncStatus = "Downloading update..."
        
        let (compressedData, _) = try await URLSession.shared.data(from: databaseURL)
        
        self.syncStatus = "Processing database..."
        let dbURL = localDatabaseURL
        
        let newRecords = try await Task.detached {
          guard let decompressedData = try? (compressedData as NSData).decompressed(using: .lzfse) as Data else {
            throw SyncError.decompressionFailed
          }
          
          let records = try PropertyListDecoder().decode([CardImageHashRecord].self, from: decompressedData)
          try decompressedData.write(to: dbURL, options: .atomic)
          
          return records
        }.value
        
        UserDefaults.standard.set(remoteManifest.version, forKey: "LocalDBVersion")
        self.records = newRecords
        self.isReady = true
        self.syncStatus = "Up to date (\(newRecords.count) cards)"
      } else {
        self.syncStatus = "Database is up to date."
      }
    } catch {
      if !self.isReady {
        self.syncStatus = "Failed to sync: Check internet connection."
      }
    }
  }
}

public struct MatchResult: Sendable {
  let id: String
  let distance: Int
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
