import ComposableArchitecture
import ScryfallKit

public protocol MagicCardQueryRequestClient: Sendable {
  func queryCards(_ query: SearchQuery) async throws -> ObjectList<Card>
  func queryCards(for id: String) async throws -> ObjectList<Card>
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
  
  public func queryCards(for id: String) async throws -> ObjectList<Card> {
    let value = try await getCard(identifier: .scryfallID(id: id))
    var cards: [Card] = []
    if let oracleId = value.oracleId {
      cards = try await searchCards(
        filters: [.oracleId(oracleId), .game(.paper)],
        unique: .prints,
        order: .released,
        sortDirection: .desc,
        includeExtras: true,
        includeMultilingual: false,
        includeVariations: true,
        page: 1
      )
      .data
    }
    
    if let index = cards.firstIndex(of: value) {
      cards.remove(at: index)
    }
    
    cards.insert(value, at: 0)
    
    return ObjectList(
      data: cards,
      hasMore: false,
      nextPage: nil,
      totalCards: cards.count,
      warnings: nil
    )
  }
}
