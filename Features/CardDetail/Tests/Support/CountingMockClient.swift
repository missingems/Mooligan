@testable import CardDetail
import Foundation
import Networking
import ScryfallKit

actor CountingMockClient: PriceHistoryClient {
  private(set) var calls = 0

  func history(for card: Card, provider: PriceProvider, listType: PriceListType) async throws -> PriceHistory {
    calls += 1
    return try await MockPriceHistoryClient().history(for: card, provider: provider, listType: listType)
  }

  func histories(for card: Card, requests: [PriceSeriesRequest]) async throws -> [PriceSeriesRequest: PriceHistory] {
    calls += 1
    return try await MockPriceHistoryClient().histories(for: card, requests: requests)
  }
}
