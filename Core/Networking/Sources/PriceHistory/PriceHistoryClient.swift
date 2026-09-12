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
}

public extension PriceHistoryClient {
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
