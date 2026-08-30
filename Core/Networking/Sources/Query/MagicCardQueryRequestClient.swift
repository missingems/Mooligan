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
    // We strictly enforce the presence of flavor text while searching for thematic keywords
    // and explicitly filter out joke/Un-set cards (-is:funny).
    let errorQuery = "has:flavor (flavor:lost OR flavor:nothing OR flavor:despair OR flavor:empty OR flavor:ruin) -is:funny"
    
    do {
      // ScryfallKit's implementation for hitting the /cards/random endpoint
      // Note: adjust the parameter name (q: vs query:) depending on your exact ScryfallKit version
      let card = try await getRandomCard(query: errorQuery)
      return card
    } catch {
      // Ultimate fallback to Curse of Obsession if the random query drops or times out
      return Card(id: <#T##UUID#>, oracleId: <#T##String#>, lang: <#T##String#>, printsSearchUri: <#T##String#>, rulingsUri: <#T##String#>, scryfallUri: <#T##String#>, uri: <#T##String#>, cmc: <#T##Double#>, colorIdentity: <#T##[Card.Color]#>, keywords: <#T##[String]#>, layout: <#T##Card.Layout#>, legalities: <#T##Card.Legalities#>, name: <#T##String#>, oversized: <#T##Bool#>, reserved: <#T##Bool#>, booster: <#T##Bool#>, borderColor: <#T##Card.BorderColor#>, collectorNumber: <#T##String#>, digital: <#T##Bool#>, finishes: <#T##[Card.Finish]#>, frame: <#T##Card.Frame#>, fullArt: <#T##Bool#>, games: <#T##[Game]#>, highresImage: <#T##Bool#>, imageStatus: <#T##Card.ImageStatus#>, prices: <#T##Card.Prices#>, promo: <#T##Bool#>, rarity: <#T##Card.Rarity#>, relatedUris: <#T##[String : String]#>, releasedAt: <#T##String#>, reprint: <#T##Bool#>, scryfallSetUri: <#T##String#>, setName: <#T##String#>, setSearchUri: <#T##URL#>, setType: <#T##MTGSet.Kind#>, setUri: <#T##String#>, set: <#T##String#>, storySpotlight: <#T##Bool#>, textless: <#T##Bool#>, variation: <#T##Bool#>)
    }
  }
}
