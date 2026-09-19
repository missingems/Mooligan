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
