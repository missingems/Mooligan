import Foundation

public struct BulkDataItem: Codable, Equatable, Sendable, Identifiable {
  public let id: String
  public let type: String
  public let name: String
  public let description: String
  public let uri: String
  public let updatedAt: String
  public let jsonlDownloadURI: String
  public let compressedSize: Int

  enum CodingKeys: String, CodingKey {
    case id, type, name, description, uri
    case updatedAt = "updated_at"
    case jsonlDownloadURI = "jsonl_download_uri"
    case compressedSize = "compressed_size"
  }

  public init(
    id: String,
    type: String,
    name: String,
    description: String,
    uri: String,
    updatedAt: String,
    jsonlDownloadURI: String,
    compressedSize: Int
  ) {
    self.id = id
    self.type = type
    self.name = name
    self.description = description
    self.uri = uri
    self.updatedAt = updatedAt
    self.jsonlDownloadURI = jsonlDownloadURI
    self.compressedSize = compressedSize
  }
}

public extension BulkDataItem {
  static let defaultCardsType = "default_cards"
}
