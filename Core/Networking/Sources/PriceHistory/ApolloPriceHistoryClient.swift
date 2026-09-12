#if MTGGRAPHQL_GENERATED
import Apollo
import ApolloAPI
import Foundation
import ScryfallKit

public final class ApolloPriceHistoryClient: PriceHistoryClient, @unchecked Sendable {
  private let apollo: ApolloClient?
  
  public init(endpoint: MTGGraphQLEndpoint? = .fromBundle()) {
    guard let endpoint else {
      self.apollo = nil
      return
    }
    
    // 1. Dedicated background operation queue for Apollo network tasks and JSON parsing
    let backgroundQueue: OperationQueue = {
      let queue = OperationQueue()
      queue.maxConcurrentOperationCount = 2
      queue.qualityOfService = .background
      queue.name = "com.mooligan.apollo-background-queue"
      return queue
    }()
    
    // 2. Bind the session client to the background queue
    let sessionClient = URLSessionClient(sessionConfiguration: .default, callbackQueue: backgroundQueue)
    let store = ApolloStore(cache: InMemoryNormalizedCache())
    let provider = DefaultInterceptorProvider(client: sessionClient, store: store)
    
    let transport = RequestChainNetworkTransport(
      interceptorProvider: provider,
      endpointURL: endpoint.url
    )
    
    self.apollo = ApolloClient(networkTransport: transport, store: store)
  }
  
  public func history(
    for card: Card,
    provider: PriceProvider,
    listType: PriceListType
  ) async throws -> PriceHistory {
    guard let apollo else { throw PriceHistoryClientError.notConfigured }
    
    let rows = try await Self.fetchRows(apollo: apollo, scryfallID: card.id.uuidString)
    
    return await Task.detached(priority: .background) {
      PriceHistoryMapper.makeHistory(
        cardID: card.id.uuidString,
        rows: rows,
        provider: provider,
        listType: listType
      )
    }.value
  }
  
  static func fetchRows(
    apollo: ApolloClient,
    scryfallID: String
  ) async throws -> [MTGGraphQLPriceRow] {
    try await withCheckedThrowingContinuation { continuation in
      apollo.fetch(
        query: MTGGraphQLAPI.CardPriceHistoryQuery(scryfallId: scryfallID.lowercased()),
        cachePolicy: .returnCacheDataElseFetch,
        queue: DispatchQueue.global(qos: .background)
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
