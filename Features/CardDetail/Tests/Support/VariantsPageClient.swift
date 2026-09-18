@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit

/// A card detail client that answers every prints request with the page a test gives it, or fails
/// the request when it is given none, and records which pages were asked for. It finds the card's
/// set only when given one, has no rulings and no related cards, so a test sees exactly what the
/// prints request did.
struct VariantsPageClient: MagicCardDetailRequestClient {
  /// What every prints request answers with; nil makes the request fail as it does offline.
  let variants: ObjectList<Card>?
  /// The card's set; nil makes the request fail as it does offline.
  var set: MTGSet?
  /// Every page of prints asked for, in order.
  let requestedPages = LockIsolated<[Int]>([])

  func getVariants(of card: Card, page: Int) async throws -> ObjectList<Card> {
    requestedPages.withValue { $0.append(page) }
    guard let variants else { throw URLError(.notConnectedToInternet) }
    return variants
  }

  func getSet(of card: Card) async throws -> MTGSet {
    guard let set else { throw URLError(.notConnectedToInternet) }
    return set
  }

  func getRulings(of card: Card) async throws -> [MagicCardRuling] {
    []
  }

  func getRelatedCardsIfNeeded(
    of card: Card,
    for type: Card.RelatedCard.Component
  ) async throws -> CardDataSource? {
    nil
  }
}
