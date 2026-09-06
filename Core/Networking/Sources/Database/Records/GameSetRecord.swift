import Foundation
import ScryfallKit
import SQLiteData

@Table("gameSets")
public struct GameSetRecord: Equatable, Sendable {
  @Column(as: UUID.BytesRepresentation.self)
  public var id: UUID
  public var code: String
  public var name: String
  public var releasedAt: String?
  public var parentSetCode: String?
  public var cardCount: Int
  public var isDigital: Bool
  public var payload: Data
  public var fetchedAt: Int64

  public init(
    id: UUID,
    code: String,
    name: String,
    releasedAt: String?,
    parentSetCode: String?,
    cardCount: Int,
    isDigital: Bool,
    payload: Data,
    fetchedAt: Int64
  ) {
    self.id = id
    self.code = code
    self.name = name
    self.releasedAt = releasedAt
    self.parentSetCode = parentSetCode
    self.cardCount = cardCount
    self.isDigital = isDigital
    self.payload = payload
    self.fetchedAt = fetchedAt
  }
}

public extension GameSetRecord {
  init(set: MTGSet, fetchedAt: Date) throws {
    self.init(
      id: set.id,
      code: set.code,
      name: set.name,
      releasedAt: set.releasedAt,
      parentSetCode: set.parentSetCode,
      cardCount: set.cardCount,
      isDigital: set.digital,
      payload: try JSONEncoder().encode(set),
      fetchedAt: Int64(fetchedAt.timeIntervalSince1970)
    )
  }

  func gameSet() throws -> MTGSet {
    try JSONDecoder().decode(MTGSet.self, from: payload)
  }
}
