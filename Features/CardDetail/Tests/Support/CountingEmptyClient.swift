@testable import CardDetail
import Foundation
import Networking
import ScryfallKit

actor CountingEmptyClient: PriceHistoryClient {
  private(set) var calls = 0

  func history(for card: Card, provider: PriceProvider, listType: PriceListType) async throws -> PriceHistory {
    calls += 1
    throw PriceHistoryClientError.emptyResponse
  }

  func histories(for card: Card, requests: [PriceSeriesRequest]) async throws -> [PriceSeriesRequest: PriceHistory] {
    calls += 1
    throw PriceHistoryClientError.emptyResponse
  }
}
