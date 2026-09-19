import Foundation

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
