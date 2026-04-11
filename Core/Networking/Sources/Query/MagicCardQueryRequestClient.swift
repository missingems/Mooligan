import ComposableArchitecture
import ScryfallKit

public protocol MagicCardQueryRequestClient: Sendable {
  func queryCards(_ query: SearchQuery) async throws -> ObjectList<Card>
  func queryCard(for id: String) async throws -> Card
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
  
  public func queryCard(for id: String) async throws -> Card {
    let value = try await getCard(identifier: .scryfallID(id: id))
    return value
  }
}
