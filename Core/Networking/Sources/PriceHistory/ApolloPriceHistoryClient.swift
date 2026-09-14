#if MTGGRAPHQL_GENERATED
import Apollo
import ApolloAPI
import Foundation
import ScryfallKit

public final class ApolloPriceHistoryClient: PriceHistoryClient, @unchecked Sendable {
  private let apollo: ApolloClient?
  
  public init(endpoint: MTGGraphQLEndpoint? = .fromBundle()) {
    self.apollo = endpoint.map(MTGGraphQLApollo.makeClient)
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
  
  public func histories(
    for card: Card,
    requests: [PriceSeriesRequest]
  ) async throws -> [PriceSeriesRequest: PriceHistory] {
    guard let apollo else { throw PriceHistoryClientError.notConfigured }

    let rows = try await Self.fetchRows(apollo: apollo, scryfallID: card.id.uuidString)
    let cardID = card.id.uuidString

    return await Task.detached(priority: .background) {
      var result: [PriceSeriesRequest: PriceHistory] = [:]
      for request in requests {
        result[request] = PriceHistoryMapper.makeHistory(
          cardID: cardID,
          rows: rows,
          provider: request.provider,
          listType: request.listType
        )
      }
      return result
    }.value
  }

  static func fetchRows(
    apollo: ApolloClient,
    scryfallID: String
  ) async throws -> [MTGGraphQLPriceRow] {
    let response = try await MTGGraphQLApollo.fetch(
      MTGGraphQLAPI.CardPriceHistoryQuery(scryfallId: scryfallID.lowercased()),
      apollo: apollo,
      queue: DispatchQueue.global(qos: .background)
    )

    if let message = response.errors?.first?.message {
      throw PriceHistoryClientError.server(message)
    }
    guard let card = response.data?.cards.first else {
      throw PriceHistoryClientError.emptyResponse
    }
    return card.prices.map { price in
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
  }
}

enum MTGGraphQLApollo {
  static func fetch<Query: GraphQLQuery>(
    _ query: Query,
    apollo: ApolloClient,
    queue: DispatchQueue
  ) async throws -> GraphQLResult<Query.Data> {
    let request = CancellableRequest<Query.Data>()
    let cancellation: any RequestCancellation = request
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        request.begin(continuation) {
          apollo.fetch(query: query, cachePolicy: .returnCacheDataElseFetch, queue: queue) { result in
            request.finish(with: result)
          }
        }
      }
    } onCancel: {
      cancellation.cancel()
    }
  }

  static func makeClient(endpoint: MTGGraphQLEndpoint) -> ApolloClient {
    let backgroundQueue: OperationQueue = {
      let queue = OperationQueue()
      queue.maxConcurrentOperationCount = 2
      queue.qualityOfService = .background
      queue.name = "com.mooligan.apollo-background-queue"
      return queue
    }()

    let sessionClient = URLSessionClient(sessionConfiguration: .default, callbackQueue: backgroundQueue)
    let store = ApolloStore(cache: InMemoryNormalizedCache())
    let provider = DefaultInterceptorProvider(client: sessionClient, store: store)

    let transport = RequestChainNetworkTransport(
      interceptorProvider: provider,
      endpointURL: endpoint.url
    )

    return ApolloClient(networkTransport: transport, store: store)
  }
}
protocol RequestCancellation: Sendable {
  func cancel()
}

final class CancellableRequest<Data: RootSelectionSet>: RequestCancellation, @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<GraphQLResult<Data>, any Error>?
  private var inFlight: (any Cancellable)?
  private var isCancelled = false

  func begin(
    _ continuation: CheckedContinuation<GraphQLResult<Data>, any Error>,
    start: () -> any Cancellable
  ) {
    lock.lock()
    guard isCancelled == false else {
      lock.unlock()
      continuation.resume(throwing: CancellationError())
      return
    }
    self.continuation = continuation
    lock.unlock()

    let request = start()

    lock.lock()
    let cancelledWhileStarting = isCancelled
    if cancelledWhileStarting == false { inFlight = request }
    lock.unlock()

    if cancelledWhileStarting { request.cancel() }
  }

  func finish(with result: Result<GraphQLResult<Data>, any Error>) {
    lock.lock()
    let continuation = self.continuation
    self.continuation = nil
    inFlight = nil
    lock.unlock()

    nonisolated(unsafe) let delivered = result
    continuation?.resume(with: delivered)
  }

  func cancel() {
    lock.lock()
    isCancelled = true
    let continuation = self.continuation
    let request = inFlight
    self.continuation = nil
    inFlight = nil
    lock.unlock()

    request?.cancel()
    continuation?.resume(throwing: CancellationError())
  }
}
#endif
