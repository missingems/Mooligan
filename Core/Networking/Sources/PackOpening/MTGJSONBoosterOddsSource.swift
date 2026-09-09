import Foundation
import ScryfallKit

/// Reads real booster sheet weights from MTGJSON's per-set data file.
///
/// MTGJSON publishes, per set, the exact sheet/weight configuration Wizards
/// uses to print boosters: named "sheets" a product draws from, and a weight
/// per card within each sheet. This is not an estimate — the numbers below are
/// computed by summing those real per-card weights, grouped by rarity.
///
/// What this does *not* attempt is the full sheet system. A real Collector
/// Booster draws from a dozen named sheets, each a distinct visual-treatment
/// tier (extended art, showcase, borderless…), which this app's simpler
/// common/uncommon/rare-or-mythic/wildcard slot model has no place for.
/// Rebuilding that slot model around MTGJSON's shape would be a much larger
/// change than the roller this feeds; instead this recovers only the three
/// numbers the existing roller actually needs — the mythic rate, and the
/// rarity split of the plain and foil "any rarity" slots — from whichever
/// sheets unambiguously match. A set or product whose sheets don't match
/// (Collector Boosters, structurally, almost never do) falls back per field
/// rather than guess: see `Dictionary.odds(rarityByUUID:)` below.
public actor MTGJSONBoosterOddsSource: BoosterOddsSource {
  private let session: URLSession
  private var cache: [String: BoosterPackOdds] = [:]
  private var inFlight: [String: Task<BoosterPackOdds, Never>] = [:]

  public init(session: URLSession = .shared) {
    self.session = session
  }

  public func odds(forSet setCode: String, kind: BoosterPackKind) async -> BoosterPackOdds {
    let key = "\(setCode.lowercased())/\(kind.rawValue)"

    if let cached = cache[key] { return cached }
    if let running = inFlight[key] { return await running.value }

    let task = Task<BoosterPackOdds, Never> { [session] in
      (try? await Self.fetchAndParse(setCode: setCode, kind: kind, session: session)) ?? .fallback
    }
    inFlight[key] = task

    let value = await task.value
    cache[key] = value
    inFlight[key] = nil
    return value
  }

  private static func fetchAndParse(
    setCode: String,
    kind: BoosterPackKind,
    session: URLSession
  ) async throws -> BoosterPackOdds {
    guard let url = URL(string: "https://mtgjson.com/api/v5/\(setCode.uppercased()).json") else {
      throw URLError(.badURL)
    }

    let (data, response) = try await session.data(from: url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }

    let file = try JSONDecoder().decode(MTGJSONSetFile.self, from: data)
    return file.data.odds(for: kind)
  }
}

// MARK: - Decode models

/// Deliberately minimal: only the two fields this needs out of a multi-megabyte
/// file. `Decodable` still has to tokenize the rest of each card's JSON to skip
/// it, but decodes no Swift representation for any field beyond these two.
struct MTGJSONSetFile: Decodable {
  let data: MTGJSONSetData
}

struct MTGJSONSetData: Decodable {
  let booster: [String: MTGJSONBoosterConfig]?
  let cards: [MTGJSONCardStub]

  /// Real odds for `kind`, or `BoosterPackOdds.fallback` field-by-field where
  /// this set's data doesn't yield a confident number. A set can end up with
  /// some real fields and some fallback fields — mythic rate recovered but the
  /// wildcard split not, say — rather than an all-or-nothing result, so a
  /// coverage gap in one number doesn't discard the other two.
  func odds(for kind: BoosterPackKind) -> BoosterPackOdds {
    guard
      let booster,
      let config = booster[mtgjsonKey(for: kind)] ?? fallbackConfig(for: kind, in: booster)
    else {
      return .fallback
    }

    let rarityByUUID = Dictionary(
      uniqueKeysWithValues: cards.compactMap { card in card.rarity.map { (card.uuid, $0) } }
    )

    return config.sheets.odds(rarityByUUID: rarityByUUID)
  }

  /// MTGJSON's own key for this product.
  private func mtgjsonKey(for kind: BoosterPackKind) -> String {
    switch kind {
    case .play: "play"
    case .draft: "draft"
    case .collector: "collector"
    }
  }

  /// Sets that retired Draft Boosters for Play Boosters (2024 on) have no
  /// "draft" key. `stockedPackKinds` only offers `.draft` for sets old enough
  /// to have one, so this exists for the narrower case of a `.play` request
  /// against a set MTGJSON only ever gave a "draft" config: the two products
  /// are close enough in shape — commons, uncommons, one rare slot, a
  /// wildcard — that borrowing the sibling's real numbers beats a guess.
  private func fallbackConfig(
    for kind: BoosterPackKind,
    in booster: [String: MTGJSONBoosterConfig]
  ) -> MTGJSONBoosterConfig? {
    guard kind == .play else { return nil }
    return booster["draft"]
  }
}

struct MTGJSONCardStub: Decodable {
  let uuid: String
  let rarity: Card.Rarity?
}

struct MTGJSONBoosterConfig: Decodable {
  let sheets: [String: MTGJSONBoosterSheet]
}

struct MTGJSONBoosterSheet: Decodable {
  /// Card uuid to its weight within this sheet.
  let cards: [String: Double]
  let foil: Bool
}

// MARK: - Sheet matching

private extension Dictionary where Key == String, Value == MTGJSONBoosterSheet {
  /// Builds `BoosterPackOdds` from whichever sheets are unambiguously
  /// recognisable, falling back per-field otherwise.
  func odds(rarityByUUID: [String: Card.Rarity]) -> BoosterPackOdds {
    let fallback = BoosterPackOdds.fallback

    return BoosterPackOdds(
      mythicChance: mythicChance(rarityByUUID: rarityByUUID) ?? fallback.mythicChance,
      wildcardWeights: weights(named: "wildcard", foil: false, rarityByUUID: rarityByUUID)
        ?? fallback.wildcardWeights,
      foilWildcardWeights: weights(named: "foil", foil: true, rarityByUUID: rarityByUUID)
        ?? fallback.foilWildcardWeights
    )
  }

  /// The mythic rate implied by the guaranteed rare-or-mythic slot.
  ///
  /// Matched by name (`/rare.?mythic/i`) rather than an exact string, because
  /// this one sheet's name has drifted across MTGJSON's history —
  /// "rareMythic", "rareMythicWithShowcase", "rareMythicShowcase" all appear
  /// depending on the set. Trusted only when exactly one sheet matches: a Play
  /// or Draft Booster has one such sheet, so a single match is exactly the
  /// expected, unambiguous case. A Collector Booster's several
  /// treatment-specific rare/mythic sheets ("extendedMainRareMythic",
  /// "extendedCommanderRareMythic", "rareMythicShowcase" all in the same
  /// product) each carry a *different* mythic rate for a *different* slot;
  /// there is no single "the" rate to average them into, so multiple matches
  /// here means falling back rather than quietly picking a wrong number.
  func mythicChance(rarityByUUID: [String: Card.Rarity]) -> Double? {
    let matches = self.filter { name, _ in
      name.range(of: "rare.?mythic", options: [.regularExpression, .caseInsensitive]) != nil
    }
    guard matches.count == 1, let sheet = matches.first?.value else { return nil }

    let byRarity = aggregate(sheet.cards, rarityByUUID: rarityByUUID)
    let total = byRarity.values.reduce(0, +)
    guard total > 0 else { return nil }

    return (byRarity[.mythic] ?? 0) / total
  }

  /// Rarity distribution of the sheet whose name and foil-ness exactly match.
  ///
  /// Exact name matching, not a fuzzy pattern: "wildcard" and "foil" are
  /// exactly what Play/Draft Boosters call these two slots, and matching
  /// anything looser risks pulling in a treatment-specific sheet (Collector
  /// Boosters name none of theirs either word, which is exactly why this
  /// correctly finds nothing there and falls back instead of misreading one).
  func weights(named name: String, foil: Bool, rarityByUUID: [String: Card.Rarity]) -> [RarityWeight]? {
    guard
      let sheet = self.first(where: { $0.key.caseInsensitiveCompare(name) == .orderedSame })?.value,
      sheet.foil == foil
    else {
      return nil
    }

    let byRarity = aggregate(sheet.cards, rarityByUUID: rarityByUUID)
    let total = byRarity.values.reduce(0, +)
    guard total > 0 else { return nil }

    return byRarity.map { RarityWeight(rarity: $0.key, weight: $0.value / total) }
  }

  private func aggregate(
    _ cards: [String: Double],
    rarityByUUID: [String: Card.Rarity]
  ) -> [Card.Rarity: Double] {
    var totals: [Card.Rarity: Double] = [:]
    for (uuid, weight) in cards {
      guard let rarity = rarityByUUID[uuid] else { continue }
      totals[rarity, default: 0] += weight
    }
    return totals
  }
}
