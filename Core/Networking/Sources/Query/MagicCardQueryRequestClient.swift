import ComposableArchitecture
import ScryfallKit

public protocol MagicCardQueryRequestClient: Sendable {
  func queryCards(_ query: SearchQuery) async throws -> ObjectList<Card>
  func queryCards(_ ids: [String]) async throws -> ObjectList<Card>
}

public enum MagicCardQueryRequestClientKey: DependencyKey {
  public static let liveValue: any MagicCardQueryRequestClient = ScryfallClient()
  public static let previewValue: any MagicCardQueryRequestClient = ScryfallClient()
  public static let testValue: any MagicCardQueryRequestClient = MockCardQueryRequestClient()
}

public extension DependencyValues {
  var cardQueryRequestClient: any MagicCardQueryRequestClient {
    get { self[MagicCardQueryRequestClientKey.self] }
    set { self[MagicCardQueryRequestClientKey.self] = newValue }
  }
}

extension ScryfallClient: MagicCardQueryRequestClient {
  public func queryCards(_ query: SearchQuery) async throws -> ObjectList<Card> {
    try await searchCards(
      filters: query.filters(),
      unique: .prints,
      order: query.sortMode,
      sortDirection: query.sortDirection,
      includeExtras: true,
      includeMultilingual: false,
      includeVariations: true,
      page: query.page
    )
  }
  
  public func queryCards(_ ids: [String]) async throws -> ObjectList<Card> {
    try await withThrowingTaskGroup(of: Card.self) { group in
      for id in ids {
        group.addTask {
          try await self.getCard(identifier: .scryfallID(id: id))
        }
      }
      
      var cards: [Card] = []
      for try await card in group {
        cards.append(card)
      }
      
      return ObjectList(
        data: cards,
        hasMore: false,
        nextPage: nil,
        totalCards: cards.count,
        warnings: nil
      )
    }
  }
}
