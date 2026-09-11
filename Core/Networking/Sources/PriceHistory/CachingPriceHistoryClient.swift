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

  private func lookup(
    card: Card,
    provider: PriceProvider,
    listType: PriceListType
  ) async throws -> PriceHistory {
    let key = Key(cardID: card.id.uuidString, provider: provider, listType: listType)

    let task = Task { [upstream] in
      try await upstream.history(
        for: card,
        provider: provider,
        listType: listType
      )
    }
    inFlight[key] = task
    
    defer { inFlight[key] = nil }
    let value = try await task.value
    cache[key] = (Date(), value)
    return value
  }
}

private extension PriceHistory {
  func clipped(to window: DateInterval) -> PriceHistory {
    PriceHistory(
      cardID: cardID,
      provider: provider,
      listType: listType,
      currency: currency,
      series: series
    )
  }
}
