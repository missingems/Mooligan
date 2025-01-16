import ComposableArchitecture
import ScryfallKit

public protocol MagicCardQueryRequestClient: Sendable {
  func queryCards(_ query: QueryType) async throws -> ObjectList<Card>
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
  public func queryCards(_ query: QueryType) async throws -> ObjectList<Card> {
    switch query {
    case let .query(_, filters, sortMode, sortDirection, page):
      try await searchCards(
        filters: Array(filters),
        unique: .prints,
        order: sortMode,
        sortDirection: sortDirection,
        includeExtras: true,
        includeMultilingual: false,
        includeVariations: true,
        page: page
      )
      
    case let .search(text, page):
      try await searchCards(
        query: text,
        unique: .prints,
        order: nil,
        sortDirection: nil,
        includeExtras: true,
        includeMultilingual: false,
        includeVariations: true,
        page: page
      )
    }
  }
}
