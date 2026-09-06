import Foundation
import ScryfallKit

public enum CardPayloadCodec {
  static let algorithm: NSData.CompressionAlgorithm = .zlib

  public static func decodeScryfall(_ data: Data) throws -> Card {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(Card.self, from: data)
  }

  public static func encode(_ card: Card) throws -> Data {
    let json = try JSONEncoder().encode(card)
    return try (json as NSData).compressed(using: algorithm) as Data
  }

  public static func decode(_ payload: Data) throws -> Card {
    let json = try (payload as NSData).decompressed(using: algorithm) as Data
    return try JSONDecoder().decode(Card.self, from: json)
  }
}
