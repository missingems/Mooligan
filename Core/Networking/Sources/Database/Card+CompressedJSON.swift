import Foundation
import ScryfallKit
import SQLiteData

public extension Card {
  struct CompressedJSONRepresentation: QueryRepresentable {
    public var queryOutput: Card

    public init(queryOutput: Card) {
      self.queryOutput = queryOutput
    }
  }
}

extension Card.CompressedJSONRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    do {
      return .blob([UInt8](try CardPayloadCodec.encode(queryOutput)))
    } catch {
      return .invalid(QueryBindingError(underlyingError: error))
    }
  }
}

extension Card.CompressedJSONRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    let bytes = try [UInt8](decoder: &decoder)
    self.init(queryOutput: try CardPayloadCodec.decode(Data(bytes)))
  }
}

extension Card.CompressedJSONRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    [UInt8].typeAffinity
  }
}
