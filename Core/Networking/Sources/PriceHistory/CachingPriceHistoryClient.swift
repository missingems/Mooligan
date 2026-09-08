import Foundation
import ScryfallKit

/// In-memory memoisation in front of any `PriceHistoryClient`.
///
/// MTGGraphQL allows 500 requests per access token per hour and the proxy shares
/// one token across every install, so the client should ask for a given card at
/// most a few times a day. Price data only moves daily, which makes a long TTL
/// free in accuracy terms.
public actor CachingPriceHistoryClient: PriceHistoryClient {
  private struct Key: Hashable {
    let cardID: String
    let provider: PriceProvider
    let listType: PriceListType
  }

  private let upstream: any PriceHistoryClient
  private let ttl: TimeInterval
  private var cache: [Key: (fetchedAt: Date, value: PriceHistory)] = [:]
  /// De-duplicates concurrent asks for the same card — the pager can request the
  /// same card from several pages at once during a fast swipe.
  private var inFlight: [Key: Task<PriceHistory, any Error>] = [:]

  public init(upstream: any PriceHistoryClient, ttl: TimeInterval = 6 * 60 * 60) {
    self.upstream = upstream
    self.ttl = ttl
  }

  public nonisolated func history(
    for card: Card,
    provider: PriceProvider,
    listType: PriceListType,
    window: DateInterval
  ) async throws -> PriceHistory {
    try await lookup(card: card, provider: provider, listType: listType, window: window)
  }

  private func lookup(
    card: Card,
    provider: PriceProvider,
    listType: PriceListType,
    window: DateInterval
  ) async throws -> PriceHistory {
    let key = Key(cardID: card.id.uuidString, provider: provider, listType: listType)

    if let hit = cache[key], Date().timeIntervalSince(hit.fetchedAt) < ttl {
      return hit.value.clipped(to: window)
    }
    if let running = inFlight[key] {
      return try await running.value.clipped(to: window)
    }

    let task = Task { [upstream] in
      // Always fetch the full retained history; `window` only trims what we return,
      // so a widened window doesn't force a second network round trip.
      try await upstream.history(
        for: card,
        provider: provider,
        listType: listType,
        window: DateInterval(start: .distantPast, end: .now)
      )
    }
    inFlight[key] = task

    defer { inFlight[key] = nil }
    let value = try await task.value
    cache[key] = (Date(), value)
    return value.clipped(to: window)
  }
}

private extension PriceHistory {
  func clipped(to window: DateInterval) -> PriceHistory {
    PriceHistory(
      cardID: cardID,
      provider: provider,
      listType: listType,
      // Carry the currency the API reported through the clip. Dropping it fell
      // back to the provider default, which silently relabels a Cardmarket
      // series as USD.
      currency: currency,
      series: series.mapValues { $0.filter { window.contains($0.date) } }
    )
  }
}
