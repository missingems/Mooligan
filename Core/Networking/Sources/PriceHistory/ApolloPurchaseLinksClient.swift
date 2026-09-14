#if MTGGRAPHQL_GENERATED
import Apollo
import ApolloAPI
import Foundation
import ScryfallKit

public final class ApolloPurchaseLinksClient: PurchaseLinksClient, @unchecked Sendable {
  private let apollo: ApolloClient?

  public init(endpoint: MTGGraphQLEndpoint? = .fromBundle()) {
    self.apollo = endpoint.map(MTGGraphQLApollo.makeClient)
  }

  public func purchaseLinks(for card: Card) async throws -> [PurchaseLink] {
    guard let apollo else { throw PriceHistoryClientError.notConfigured }

    let response = try await MTGGraphQLApollo.fetch(
      MTGGraphQLAPI.CardPurchaseUrlsQuery(scryfallId: card.id.uuidString.lowercased()),
      apollo: apollo,
      queue: DispatchQueue.global(qos: .userInitiated)
    )

    if let message = response.errors?.first?.message {
      throw PriceHistoryClientError.server(message)
    }
    guard let match = response.data?.cards.first else {
      throw PriceHistoryClientError.emptyResponse
    }

    let urls = match.purchaseUrls.map { purchaseUrls in
      MTGGraphQLPurchaseUrls(
        tcgplayer: purchaseUrls.tcgplayer,
        cardKingdom: purchaseUrls.cardKingdom,
        cardKingdomFoil: purchaseUrls.cardKingdomFoil,
        cardmarket: purchaseUrls.cardmarket
      )
    }

    return PurchaseLinksMapper.makeLinks(from: urls)
  }
}
#endif
