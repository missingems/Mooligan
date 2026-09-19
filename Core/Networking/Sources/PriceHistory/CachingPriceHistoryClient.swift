import Foundation
import ScryfallKit

/// Price histories kept in the database until MTGJSON makes a new build.
///
/// MTGGraphQL serves MTGJSON's daily build, so a history stored from one build is the answer until
/// the next: a card opened again, today or after a relaunch, costs nothing against the token's 500
/// requests an hour. When the feed cannot be reached, the last stored history is shown rather
/// than nothing, however old.
public actor CachingPriceHistoryClient: PriceHistoryClient {
  private struct Key: Hashable {
    let cardID: String
    let requests: [PriceSeriesRequest]
  }

  private let upstream: any PriceHistoryClient
  private let build: @Sendable () async -> String?
  private let store = PriceHistoryStore()
  private var inFlight: [Key: Task<[PriceSeriesRequest: PriceHistory], any Error>] = [:]

  public init(
    upstream: any PriceHistoryClient,
    build: @escaping @Sendable () async -> String? = { await MTGJSONBuild.shared.version() }
  ) {
    self.upstream = upstream
    self.build = build
  }

  public nonisolated func history(
    for card: Card,
    provider: PriceProvider,
    listType: PriceListType
  ) async throws -> PriceHistory {
    let request = PriceSeriesRequest(provider: provider, listType: listType)
    guard let history = try await lookup(card: card, requests: [request])[request] else {
      throw PriceHistoryClientError.emptyResponse
    }
    return history
  }

  public nonisolated func histories(
    for card: Card,
    requests: [PriceSeriesRequest]
  ) async throws -> [PriceSeriesRequest: PriceHistory] {
    try await lookup(card: card, requests: requests)
  }

  /// One lookup per card and set of series at a time: a second caller waits for the first.
  private func lookup(
    card: Card,
    requests: [PriceSeriesRequest]
  ) async throws -> [PriceSeriesRequest: PriceHistory] {
    let key = Key(cardID: card.id.uuidString, requests: requests)
    if let task = inFlight[key] { return try await task.value }

    let task = Task { [upstream, build, store] in
      let cardID = card.id.uuidString
      let version = await build()
      let stored = (try? await store.records(cardID: cardID, requests: requests)) ?? [:]
      let now = Date()

      let histories = Self.histories(from: stored)
      if histories.count == requests.count,
        stored.values.allSatisfy({ $0.isCurrent(build: version, now: now) })
      {
        return histories
      }

      do {
        let fetched = try await upstream.histories(for: card, requests: requests)
        try? await store.save(fetched.values, mtgjsonVersion: version)
        return fetched
      } catch {
        guard histories.isEmpty == false else { throw error }
        return histories
      }
    }
    inFlight[key] = task
    defer { inFlight[key] = nil }
    return try await task.value
  }

  private static func histories(
    from records: [PriceSeriesRequest: PriceHistoryRecord]
  ) -> [PriceSeriesRequest: PriceHistory] {
    Dictionary(uniqueKeysWithValues: records.compactMap { request, record in
      (try? record.history(for: request)).map { (request, $0) }
    })
  }
}
