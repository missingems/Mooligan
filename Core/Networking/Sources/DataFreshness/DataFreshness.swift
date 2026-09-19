import Foundation

/// When each dataset the app downloads was last brought up to date, for the Developer section of
/// Settings.
public struct DataFreshness: Equatable, Sendable {
  /// Scryfall's bulk card catalog: when it was last checked for a new export, and ingested.
  public var catalog: SyncStateRecord?
  /// Scryfall's list of sets.
  public var setsFetchedAt: Date?
  /// Search pages kept from Scryfall.
  public var cardPages: StoredDataset
  /// MTGJSON's current build, as last asked.
  public var mtgjsonBuild: String?
  public var mtgjsonBuildAskedAt: Date?
  public var boosterOdds: StoredDataset
  public var pullOdds: StoredDataset
  public var priceHistories: StoredDataset
  /// The card image database the scanner matches against.
  public var cardImageHashes: CardHashDatabaseManifest?
  public var cardImageHashesUpdatedAt: Date?

  public init(
    catalog: SyncStateRecord? = nil,
    setsFetchedAt: Date? = nil,
    cardPages: StoredDataset = StoredDataset(),
    mtgjsonBuild: String? = nil,
    mtgjsonBuildAskedAt: Date? = nil,
    boosterOdds: StoredDataset = StoredDataset(),
    pullOdds: StoredDataset = StoredDataset(),
    priceHistories: StoredDataset = StoredDataset(),
    cardImageHashes: CardHashDatabaseManifest? = nil,
    cardImageHashesUpdatedAt: Date? = nil
  ) {
    self.catalog = catalog
    self.setsFetchedAt = setsFetchedAt
    self.cardPages = cardPages
    self.mtgjsonBuild = mtgjsonBuild
    self.mtgjsonBuildAskedAt = mtgjsonBuildAskedAt
    self.boosterOdds = boosterOdds
    self.pullOdds = pullOdds
    self.priceHistories = priceHistories
    self.cardImageHashes = cardImageHashes
    self.cardImageHashesUpdatedAt = cardImageHashesUpdatedAt
  }
}
