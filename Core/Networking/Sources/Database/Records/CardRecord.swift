import Foundation
import ScryfallKit
import SQLiteData

@Table("cards")
public struct CardRecord: Equatable, Sendable {
  public enum Source: Int, Sendable {
    case api = 0
    case bulk = 1
  }

  @Column(as: UUID.BytesRepresentation.self)
  public var id: UUID
  public var oracleID: String?
  public var name: String
  public var setCode: String
  @Column(as: UUID.BytesRepresentation?.self)
  public var setID: UUID?
  public var collectorNumber: String
  public var collectorNumberSort: String
  public var releasedAt: String
  public var rarityRank: Int
  public var colorRank: Int
  public var cmc: Double?
  public var typeLine: String?
  public var colorIdentity: String
  public var usd: Double?
  /// The name as Scryfall compares it, with nothing but its letters and digits. Nil on rows stored
  /// before the column existed, until `CardStore.backfillSortKeys()` has written it.
  public var sortName: String?
  public var isFullArt: Bool
  /// The cheapest way Scryfall quotes the printing: non-foil, else foil, else etched.
  public var sortPrice: Double?
  public var isDigital: Bool
  public var isPaper: Bool
  @Column(as: Card.CompressedJSONRepresentation.self)
  public var card: Card
  public var ingestedAt: Int64
  public var source: Int

  public init(
    id: UUID,
    oracleID: String?,
    name: String,
    setCode: String,
    setID: UUID?,
    collectorNumber: String,
    collectorNumberSort: String,
    releasedAt: String,
    rarityRank: Int,
    colorRank: Int,
    cmc: Double?,
    typeLine: String?,
    colorIdentity: String,
    usd: Double?,
    sortName: String?,
    isFullArt: Bool,
    sortPrice: Double?,
    isDigital: Bool,
    isPaper: Bool,
    card: Card,
    ingestedAt: Int64,
    source: Int
  ) {
    self.id = id
    self.oracleID = oracleID
    self.name = name
    self.setCode = setCode
    self.setID = setID
    self.collectorNumber = collectorNumber
    self.collectorNumberSort = collectorNumberSort
    self.releasedAt = releasedAt
    self.rarityRank = rarityRank
    self.colorRank = colorRank
    self.cmc = cmc
    self.typeLine = typeLine
    self.colorIdentity = colorIdentity
    self.usd = usd
    self.sortName = sortName
    self.isFullArt = isFullArt
    self.sortPrice = sortPrice
    self.isDigital = isDigital
    self.isPaper = isPaper
    self.card = card
    self.ingestedAt = ingestedAt
    self.source = source
  }
}

public extension CardRecord {
  init(card: Card, source: Source, ingestedAt: Date) {
    self.init(
      id: card.id,
      oracleID: card.oracleId,
      name: card.name,
      setCode: card.set,
      setID: card.setId,
      collectorNumber: card.collectorNumber,
      collectorNumberSort: CollectorNumber.sortKey(card.collectorNumber),
      releasedAt: card.releasedAt,
      rarityRank: Self.rarityRank(for: card.rarity),
      colorRank: Self.colorRank(for: card),
      cmc: card.cmc,
      typeLine: card.typeLine,
      colorIdentity: Self.colorIdentityKey(card.colorIdentity),
      usd: card.prices.usd.flatMap(Double.init),
      sortName: Self.sortName(card.name),
      isFullArt: card.fullArt,
      sortPrice: (card.prices.usd ?? card.prices.usdFoil ?? card.prices.usdEtched).flatMap(Double.init),
      isDigital: card.digital,
      isPaper: card.games.contains(.paper),
      card: card,
      ingestedAt: Int64(ingestedAt.timeIntervalSince1970),
      source: source.rawValue
    )
  }

  static func rarityRank(for rarity: Card.Rarity) -> Int {
    switch rarity {
    case .bonus: 0
    case .special: 1
    case .common: 2
    case .uncommon: 3
    case .rare: 4
    case .mythic: 5
    }
  }

  static func colorIdentityKey(_ colorIdentity: [Card.Color]) -> String {
    colorIdentity.sorted().map(\.rawValue).joined()
  }
}
