import ComposableArchitecture
import ScryfallKit

public protocol MagicCardQueryRequestClient: Sendable {
  func queryCards(_ query: QueryType) async throws -> ObjectList<Card>
}

public enum MagicCardQueryRequestClientKey: DependencyKey {
  public static let liveValue: any MagicCardQueryRequestClient = ScryfallClient()
  public static let previewValue: any MagicCardQueryRequestClient = ScryfallClient()
  public static let testValue: any MagicCardQueryRequestClient = ScryfallClient()
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
      
    case let .set(gameSet, page):
      try await searchCards(
        filters: [.set(gameSet.code)],
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
