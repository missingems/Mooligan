#if DEBUG
import Foundation
import ScryfallKit

/// Deterministic, offline packs for previews, the PackOpening runner and the
/// `-uiTestMode` launch path.
public struct MockBoosterPackClient: BoosterPackClient {
  private let sets: [MTGSet]
  private let source: MockBoosterPoolSource

  public init(sets: [MTGSet] = MockGameSetRequestClient.mockSets) {
    self.sets = sets
    source = MockBoosterPoolSource()
  }

  public func products() async throws -> [PackProduct] {
    sets.flatMap { set in
      [BoosterPackKind.play, .collector].map { PackProduct(set: set, kind: $0) }
    }
  }

  public func open(product: PackProduct, seed: UUID) async throws -> BoosterPack {
    let pool = try await source.pool(forSet: product.set.code)
    var generator = SeededRandomNumberGenerator(seed: seed)

    return BoosterPack(
      id: seed,
      product: product,
      cards: BoosterPackRoller.roll(kind: product.kind, from: pool, using: &generator)
    )
  }
}

/// Synthetic pool with enough distinct cards at every rarity that a rolled pack
/// has no repeats.
///
/// Fully deterministic, ids included: a mock that minted fresh `UUID`s on every
/// call would make a seeded roll irreproducible, which is the one property the
/// seed exists to provide.
public struct MockBoosterPoolSource: BoosterPoolSource {
  public init() {}

  public func pool(forSet setCode: String) async throws -> BoosterCardPool {
    BoosterCardPool(
      commons: Self.cards(rarity: .common, count: 40, setCode: setCode),
      uncommons: Self.cards(rarity: .uncommon, count: 20, setCode: setCode),
      rares: Self.cards(rarity: .rare, count: 12, setCode: setCode),
      mythics: Self.cards(rarity: .mythic, count: 5, setCode: setCode),
      lands: Self.cards(rarity: .common, count: 5, setCode: setCode, namePrefix: "Island"),
      rarityCounts: BoosterRarityCounts(common: 40, uncommon: 20, rare: 12, mythic: 5, land: 5)
    )
  }

  static func cards(
    rarity: Card.Rarity,
    count: Int,
    setCode: String,
    namePrefix: String? = nil
  ) -> [Card] {
    // `0..<count`, not `1...count`: a zero-card bucket is a legitimate request
    // (plenty of sets print no mythics) and a closed range would trap.
    (0..<count).map { index in
      let number = index + 1
      var card = Card.mock(
        id: identifier(rarity: rarity, index: number, setCode: setCode, namePrefix: namePrefix),
        name: "\(namePrefix ?? rarity.rawValue.capitalized) \(number)",
        collectorNumber: "\(number)",
        set: setCode
      )
      card.rarity = rarity
      card.booster = true
      card.games = [.paper]
      card.typeLine = namePrefix == nil ? "Creature — Test" : "Basic Land — Island"
      card.prices = Card.Prices(
        tix: nil,
        usd: String(format: "%.2f", Double(number) * (rarity == .mythic ? 3.5 : 0.2)),
        usdFoil: String(format: "%.2f", Double(number) * (rarity == .mythic ? 9.0 : 0.6)),
        eur: nil
      )
      return card
    }
  }

  /// Stable id per (set, bucket, position).
  static func identifier(
    rarity: Card.Rarity,
    index: Int,
    setCode: String,
    namePrefix: String?
  ) -> UUID {
    let key = "\(setCode)-\(namePrefix ?? rarity.rawValue)-\(index)"
    let hash = key.unicodeScalars.reduce(UInt64(14_695_981_039_346_656_037)) { partial, scalar in
      (partial ^ UInt64(scalar.value)) &* 1_099_511_628_211
    }

    return UUID(uuidString: String(format: "00000000-0000-4000-8000-%012llX", hash & 0xFFFF_FFFF_FFFF))
      ?? UUID()
  }
}
#endif
