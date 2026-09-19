import ComposableArchitecture
import Networking
import ScryfallKit

/// Serves one card, and its printings, and records what the scanner asked for.
final class CardQueryRequestClientSpy: MagicCardQueryRequestClient {
  let card: Card
  let printings: [Card]
  let requestedIDs = LockIsolated<[String]>([])
  let queries = LockIsolated<[SearchQuery]>([])

  init(card: Card, printings: [Card] = []) {
    self.card = card
    self.printings = printings
  }

  func queryCard(for id: String) async throws -> Card {
    requestedIDs.withValue { $0.append(id) }
    return card
  }

  func queryCards(_ query: SearchQuery) async throws -> ObjectList<Card> {
    queries.withValue { $0.append(query) }
    return ObjectList(data: printings.isEmpty ? [card] : printings)
  }

  func randomlyQueryErrorCard() async throws -> Card { card }
}
