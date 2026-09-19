import Dependencies
import Foundation
import ScryfallKit

/// Works a printing's pull odds out of its set's MTGJSON file, the booster
/// configuration Wizards prints the packs from.
///
/// A set file is two to eight megabytes, so each is downloaded once and boiled
/// down to every card's odds in one go: the other cards of the set, which the
/// reader is likely to swipe to next, are then a dictionary lookup. The result
/// is kept in memory for the session and in the database across launches.
public actor MTGJSONCardPullOddsSource: CardPullOddsSource {
  @Dependency(\.date) private var date
  private let session: URLSession
  private let store = SetPullOddsStore()
  private var sets: [String: SetPullOdds] = [:]
  private var inFlight: [String: Task<SetPullOdds?, Never>] = [:]

  public init(session: URLSession? = nil) {
    if let session {
      self.session = session
    } else {
      // Not the shared session's minute-long request timeout: the odds are one tile among many, and
      // a set file that stalls is better given up on and asked for again next time.
      let configuration = URLSessionConfiguration.default
      configuration.timeoutIntervalForRequest = 15
      configuration.timeoutIntervalForResource = 60
      self.session = URLSession(configuration: configuration)
    }
  }

  public func odds(for card: Card, parentSetCode: String?) async -> CardPullOdds? {
    // A set that is not out yet has no packs to open, though MTGJSON often carries its sheets
    // weeks ahead. A digital printing was never in a paper pack. Neither is worth a download.
    guard card.digital == false, isReleased(card) else { return nil }

    // Only the card's own set file maps its Scryfall id to MTGJSON's uuid, which is what every
    // product's sheets are keyed by, so it is needed even when the odds are in the parent's.
    guard
      let own = await setOdds(card.set),
      let uuid = own.uuidsByScryfallID[card.id.uuidString.lowercased()]
    else { return nil }

    var products = own.oddsByUUID[uuid] ?? []
    var setProducts = own.products
    if let parentSetCode, parentSetCode.lowercased() != card.set.lowercased(),
       let parent = await setOdds(parentSetCode) {
      products += parent.oddsByUUID[uuid] ?? []
      setProducts.merge(parent.products) { own, _ in own }
    }
    return CardPullOdds(products: products, setProducts: setProducts)
  }

  /// Released on or before today. A date that does not read as one does not hold the odds back.
  private func isReleased(_ card: Card) -> Bool {
    guard let release = try? Date.ISO8601FormatStyle().year().month().day().parse(card.releasedAt) else {
      return true
    }
    return release <= date.now
  }

  /// One download per set however many of its cards ask at once: swiping through a set asks for
  /// the same file from every page.
  private func setOdds(_ setCode: String) async -> SetPullOdds? {
    let key = setCode.lowercased()
    if let cached = sets[key] { return cached }

    let task = inFlight[key] ?? Task { [session, store] in
      await Self.load(setCode: key, session: session, store: store)
    }
    inFlight[key] = task

    // The task is unstructured on purpose: a page swiped away mid-download does not cancel the
    // download, which carries on and is ready when the reader comes back. The page's own wait sees
    // it through too, and the card drops the answer on arrival since its effect was cancelled.
    let value = await task.value
    // Only this download's entry: after a failure, a newer download may have taken its place.
    if inFlight[key] == task { inFlight[key] = nil }
    if let value { sets[key] = value }
    return value
  }

  /// The stored answer while it is fresh; otherwise MTGJSON's, saved for next time. A stale answer
  /// still beats none when MTGJSON cannot be reached.
  private static func load(setCode: String, session: URLSession, store: SetPullOddsStore) async -> SetPullOdds? {
    let stored = try? await store.record(forSet: setCode)
    if let stored, store.isFresh(stored), let odds = stored.odds {
      return odds
    }

    guard let fetched = try? await fetch(setCode: setCode, session: session) else {
      return stored?.odds
    }
    try? await store.save(fetched, forSet: setCode)
    return fetched
  }

  /// Off the actor: decoding a set file takes long enough to hold up every other set's lookup.
  @concurrent
  private static func fetch(setCode: String, session: URLSession) async throws -> SetPullOdds {
    guard let url = URL(string: "https://mtgjson.com/api/v5/\(setCode.uppercased()).json") else {
      throw URLError(.badURL)
    }

    let (data, response) = try await session.data(from: url)
    switch (response as? HTTPURLResponse)?.statusCode {
    case 200:
      // A file that arrived whole but will not decode will not decode tomorrow either. Stored as
      // empty, as a missing set is, rather than downloaded again for every card of the set.
      guard let file = try? JSONDecoder().decode(MTGJSONSetFile.self, from: data) else { return .empty }
      return file.data.pullOdds(setCode: setCode)
    case 404:
      // A set MTGJSON does not carry has no odds to give, and asking again tomorrow will not change
      // that. Stored as empty so it is not downloaded again for every card.
      return .empty
    default:
      throw URLError(.badServerResponse)
    }
  }
}
