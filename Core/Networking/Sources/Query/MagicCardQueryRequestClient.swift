import ComposableArchitecture
import ScryfallKit
import Foundation

public protocol MagicCardQueryRequestClient: Sendable {
  func queryCards(_ query: SearchQuery) async throws -> ObjectList<Card>
  func queryCard(for id: String) async throws -> Card
  func randomlyQueryErrorCard() async throws -> Card
}

public enum MagicCardQueryRequestClientKey: DependencyKey {
  public static let liveValue: any MagicCardQueryRequestClient = ScryfallClient()
  public static let previewValue: any MagicCardQueryRequestClient = MockCardQueryRequestClient()
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
  
  public func randomlyQueryErrorCard() async throws -> Card {
    let errorQuery = "has:flavor (flavor:lost OR flavor:nothing OR flavor:despair OR flavor:empty OR flavor:ruin) -is:funny"
    
    do {
      let card = try await getRandomCard(query: errorQuery)
      return card
    } catch {
      return try await queryCard(for: "69ba6262-a3b1-4009-b2ed-ae684dfae022")
    }
  }
}
