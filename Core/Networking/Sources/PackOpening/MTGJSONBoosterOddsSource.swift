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

  public init(session: URLSession? = nil) {
    // Not `URLSession.shared`. These are multi-megabyte set files fetched for a
    // detail the pack can happily do without, and the shared session's minute
    // -long request timeout meant a slow one held the pack shut for a minute
    // with nothing on screen but "deciding what is in it". Anything that has
    // not arrived in a few seconds is not worth waiting for.
    if let session {
      self.session = session
    } else {
      // Longer than `deadline` on purpose: nobody is waiting on these once the
      // deadline passes, and a slow-but-progressing download is still worth
      // finishing so the next pack from this set gets the real numbers.
      let configuration = URLSessionConfiguration.default
      configuration.timeoutIntervalForRequest = 15
      configuration.timeoutIntervalForResource = 30
      self.session = URLSession(configuration: configuration)
    }
  }

  /// How long a pack waits for real odds before rolling on the built-in ones.
  static let deadline: TimeInterval = 3

  public func odds(forSet setCode: String, kind: BoosterPackKind) async -> BoosterPackOdds {
    let key = "\(setCode.lowercased())/\(kind.rawValue)"

    if let cached = cache[key] { return cached }

    let task = inFlight[key] ?? startFetch(setCode: setCode, kind: kind, key: key)

    // Wait only so long. MTGJSON's set files are megabytes and its serving is
    // uneven — some sets arrive in under two seconds and others stall part-way
    // through and never finish — so a pack that waits for them is a pack that
    // sometimes never opens. The fetch is left running when the wait expires,
    // and caches itself when it lands, so the cost of a slow set is that its
    // *first* pack of the session rolls on the built-in odds rather than that
    // the player sits looking at a progress bar.
    return await withTaskGroup(of: BoosterPackOdds?.self) { group in
      group.addTask { await task.value }
      group.addTask {
        try? await Task.sleep(for: .seconds(Self.deadline))
        return nil
      }

      let first = await group.next() ?? nil
      // Cancels the *waiting*, not the fetch: `task` is unstructured and is
      // deliberately not a child of this group.
      group.cancelAll()
      return first ?? .fallback
    }
  }

  private func startFetch(
    setCode: String,
    kind: BoosterPackKind,
    key: String
  ) -> Task<BoosterPackOdds, Never> {
    let task = Task<BoosterPackOdds, Never> { [session] in
      (try? await Self.fetchAndParse(setCode: setCode, kind: kind, session: session)) ?? .fallback
    }
    inFlight[key] = task

    Task { [weak self] in
      let value = await task.value
      await self?.store(value, for: key)
    }

    return task
  }

  private func store(_ odds: BoosterPackOdds, for key: String) {
    cache[key] = odds
    inFlight[key] = nil
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
    let scryfallByUUID = Dictionary(
      cards.compactMap { card in
        card.identifiers?.scryfallId.map { (card.uuid, $0.lowercased()) }
      },
      uniquingKeysWith: { first, _ in first }
    )

    return config.sheets.odds(
      rarityByUUID: rarityByUUID,
      scryfallByUUID: scryfallByUUID
    )
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
  struct Identifiers: Decodable {
    let scryfallId: String?
  }

  let uuid: String
  let rarity: Card.Rarity?
  /// MTGJSON keys its sheets by its own uuid; the app knows cards by their
  /// Scryfall id, so the two have to be joined here.
  let identifiers: Identifiers?
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
  func odds(
    rarityByUUID: [String: Card.Rarity],
    scryfallByUUID: [String: String]
  ) -> BoosterPackOdds {
    let fallback = BoosterPackOdds.fallback

    return BoosterPackOdds(
      mythicChance: mythicChance(rarityByUUID: rarityByUUID) ?? fallback.mythicChance,
      wildcardWeights: weights(named: "wildcard", foil: false, rarityByUUID: rarityByUUID)
        ?? fallback.wildcardWeights,
      foilWildcardWeights: weights(named: "foil", foil: true, rarityByUUID: rarityByUUID)
        ?? fallback.foilWildcardWeights,
      cardShares: cardShares(rarityByUUID: rarityByUUID, scryfallByUUID: scryfallByUUID)
    )
  }

  /// Each printing's share of its own rarity, read straight off the sheets.
  ///
  /// A card's weight only means anything next to the other cards of the same
  /// rarity on the same sheet, so shares are normalised within that group. A
  /// card that appears on several sheets — a plain printing and a showcase one,
  /// say — is taken from the first by sheet name, so the answer does not depend
  /// on dictionary ordering.
  func cardShares(
    rarityByUUID: [String: Card.Rarity],
    scryfallByUUID: [String: String]
  ) -> [String: Double] {
    var shares: [String: Double] = [:]

    for name in keys.sorted() {
      guard let sheet = self[name] else { continue }

      var totalByRarity: [Card.Rarity: Double] = [:]
      for (uuid, weight) in sheet.cards {
        guard let rarity = rarityByUUID[uuid] else { continue }
        totalByRarity[rarity, default: 0] += weight
      }

      for (uuid, weight) in sheet.cards {
        guard
          let rarity = rarityByUUID[uuid],
          let scryfallID = scryfallByUUID[uuid],
          shares[scryfallID] == nil,
          let total = totalByRarity[rarity],
          total > 0
        else { continue }

        shares[scryfallID] = weight / total
      }
    }

    return shares
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
