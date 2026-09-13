import Foundation
import ScryfallKit

public actor CachingPriceHistoryClient: PriceHistoryClient {
  private struct Key: Hashable {
    let cardID: String
    let provider: PriceProvider
    let listType: PriceListType
  }

  private let upstream: any PriceHistoryClient
  private let ttl: TimeInterval
  private var cache: [Key: (fetchedAt: Date, value: PriceHistory)] = [:]
  private var inFlight: [Key: Task<PriceHistory, any Error>] = [:]

  public init(upstream: any PriceHistoryClient, ttl: TimeInterval = 6 * 60 * 60) {
    self.upstream = upstream
    self.ttl = ttl
  }

  public nonisolated func history(
    for card: Card,
    provider: PriceProvider,
    listType: PriceListType
  ) async throws -> PriceHistory {
    try await lookup(card: card, provider: provider, listType: listType)
  }

  public nonisolated func histories(
    for card: Card,
    requests: [PriceSeriesRequest]
  ) async throws -> [PriceSeriesRequest: PriceHistory] {
    try await lookupAll(card: card, requests: requests)
  }

  private func cached(_ key: Key, now: Date) -> PriceHistory? {
    guard let entry = cache[key], now.timeIntervalSince(entry.fetchedAt) < ttl else { return nil }
    return entry.value
  }

  private func lookup(
    card: Card,
    provider: PriceProvider,
    listType: PriceListType
  ) async throws -> PriceHistory {
    let key = Key(cardID: card.id.uuidString, provider: provider, listType: listType)

    if let value = cached(key, now: Date()) { return value }
    if let task = inFlight[key] { return try await task.value }

    let task = Task { [upstream] in
      try await upstream.history(for: card, provider: provider, listType: listType)
    }
    inFlight[key] = task

    defer { inFlight[key] = nil }
    let value = try await task.value
    cache[key] = (Date(), value)
    return value
  }

  private func lookupAll(
    card: Card,
    requests: [PriceSeriesRequest]
  ) async throws -> [PriceSeriesRequest: PriceHistory] {
    let now = Date()

    var hits: [PriceSeriesRequest: PriceHistory] = [:]
    for request in requests {
      let key = Key(
        cardID: card.id.uuidString,
        provider: request.provider,
        listType: request.listType
      )
      if let value = cached(key, now: now) { hits[request] = value }
    }
    guard hits.count < requests.count else { return hits }

    let fetched = try await upstream.histories(for: card, requests: requests)

    let fetchedAt = Date()
    for (request, value) in fetched {
      let key = Key(
        cardID: card.id.uuidString,
        provider: request.provider,
        listType: request.listType
      )
      cache[key] = (fetchedAt, value)
    }
    return fetched
  }
}
