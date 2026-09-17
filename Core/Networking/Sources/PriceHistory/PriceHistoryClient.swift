import ComposableArchitecture
import Foundation
import ScryfallKit

public protocol PriceHistoryClient: Sendable {
  /// `window` bounds the returned points. MTGJSON keeps a limited (roughly
  /// three month) history, so asking for more simply returns what exists.
  func history(
    for card: Card,
    provider: PriceProvider,
    listType: PriceListType
  ) async throws -> PriceHistory

  /// Several provider/list-type pairs at once.
  ///
  /// One payload carries every vendor and both list types, so a client that
  /// talks to the feed can answer this with a single round trip. The default
  /// below cannot, and asks once per pair — correct, but a request each.
  func histories(
    for card: Card,
    requests: [PriceSeriesRequest]
  ) async throws -> [PriceSeriesRequest: PriceHistory]
}

public extension PriceHistoryClient {
  func histories(
    for card: Card,
    requests: [PriceSeriesRequest]
  ) async throws -> [PriceSeriesRequest: PriceHistory] {
    var result: [PriceSeriesRequest: PriceHistory] = [:]
    for request in requests {
      result[request] = try await history(
        for: card,
        provider: request.provider,
        listType: request.listType
      )
    }
    return result
  }

  /// The card detail view's default: TCGplayer retail over the last 90 days.
  func history(for card: Card) async throws -> PriceHistory {
    try await history(
      for: card,
      provider: .tcgplayer,
      listType: .retail
    )
  }
}

public enum PriceHistoryClientError: Error, Equatable {
  case notConfigured
  case badStatus(Int)
  case server(String)
  case emptyResponse
}

public enum PriceHistoryClientKey: DependencyKey {
  public static var liveValue: any PriceHistoryClient {
#if MTGGRAPHQL_GENERATED
    // Real path: Apollo -> your proxy -> graphql.mtgjson.com.
    // Six hour TTL keeps a browsing session far under the 500 req/hour token cap.
    CachingPriceHistoryClient(upstream: ApolloPriceHistoryClient())
#else
    // Until `apollo-ios-cli generate` has run there is no generated operation to
    // send, so the live path can't be built. See Core/Networking/GraphQL/README.md.
    UnavailablePriceHistoryClient()
#endif
  }

#if DEBUG
  public static let previewValue: any PriceHistoryClient = MockPriceHistoryClient()
  public static let testValue: any PriceHistoryClient = MockPriceHistoryClient()
#endif
}

public extension DependencyValues {
  var priceHistoryClient: any PriceHistoryClient {
    get { self[PriceHistoryClientKey.self] }
    set { self[PriceHistoryClientKey.self] = newValue }
  }
}

/// Stand-in that reports "no data" rather than trapping, so the chart degrades to
/// its empty state instead of taking the card detail screen down with it.
public struct UnavailablePriceHistoryClient: PriceHistoryClient {
  public init() {}

  public func history(
    for card: Card,
    provider: PriceProvider,
    listType: PriceListType,
  ) async throws -> PriceHistory {
    throw PriceHistoryClientError.notConfigured
  }
}
