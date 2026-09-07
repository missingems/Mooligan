#if MTGGRAPHQL_GENERATED
import Apollo
import ApolloAPI
import Foundation
import ScryfallKit
// `MTGGraphQLAPI` is a namespace enum generated into this same target
// (`embeddedInTarget` in GraphQL/apollo-codegen-config.json), so there is no
// module to import — the generated types are compiled straight into Networking.

/// Live price history, fetched with Apollo from the proxy in `Tools/mtggraphql-proxy/`.
///
/// Apollo's normalized cache is left in memory only: the proxy already caches
/// upstream responses, `CachingPriceHistoryClient` memoises on this side, and
/// adding `ApolloSQLite` would put a second SQLite stack next to the GRDB one
/// that `SQLiteData` already brings in.
/// `@unchecked Sendable` because `ApolloClient` predates strict concurrency and
/// is not annotated, but it is designed to be shared: the store, the request
/// chain and the interceptors all lock internally, and Apollo's own guidance is
/// to hold one client for the lifetime of the app. The only stored property is
/// that client, and it is never reassigned after `init`.
public final class ApolloPriceHistoryClient: PriceHistoryClient, @unchecked Sendable {
  private let apollo: ApolloClient?

  public init(endpoint: MTGGraphQLEndpoint? = .fromBundle()) {
    guard let endpoint else {
      // No proxy URL configured — every call reports `.notConfigured` and the
      // chart section stays hidden rather than the app pointing at a bad host.
      self.apollo = nil
      return
    }
    let store = ApolloStore(cache: InMemoryNormalizedCache())
    self.apollo = ApolloClient(
      networkTransport: RequestChainNetworkTransport(
        interceptorProvider: DefaultInterceptorProvider(store: store),
        endpointURL: endpoint.url
      ),
      store: store
    )
  }

  public func history(
    for card: Card,
    provider: PriceProvider,
    listType: PriceListType,
    window: DateInterval
  ) async throws -> PriceHistory {
    guard let apollo else { throw PriceHistoryClientError.notConfigured }

    let rows = try await Self.fetchRows(apollo: apollo, scryfallID: card.id.uuidString)
    return PriceHistoryMapper.makeHistory(
      cardID: card.id.uuidString,
      rows: rows,
      provider: provider,
      listType: listType,
      window: window
    )
  }

  /// Bridges Apollo's callback API and flattens the generated selection set down
  /// to `MTGGraphQLPriceRow`, which is what the mapper and its tests work with.
  ///
  /// `cards` and `prices` are both non-null lists in the schema, so an unknown
  /// card comes back as an empty array rather than nil.
  static func fetchRows(
    apollo: ApolloClient,
    scryfallID: String
  ) async throws -> [MTGGraphQLPriceRow] {
    try await withCheckedThrowingContinuation { continuation in
      apollo.fetch(
        query: MTGGraphQLAPI.CardPriceHistoryQuery(scryfallId: scryfallID),
        cachePolicy: .returnCacheDataElseFetch
      ) { result in
        switch result {
        case let .success(response):
          if let message = response.errors?.first?.message {
            continuation.resume(throwing: PriceHistoryClientError.server(message))
            return
          }
          guard let card = response.data?.cards.first else {
            continuation.resume(throwing: PriceHistoryClientError.emptyResponse)
            return
          }
          continuation.resume(
            returning: card.prices.map { price in
              MTGGraphQLPriceRow(
                provider: price.provider,
                date: price.date,
                cardType: price.cardType,
                listType: price.listType,
                currency: price.currency,
                format: price.format,
                price: price.price
              )
            }
          )
        case let .failure(error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
#endif
