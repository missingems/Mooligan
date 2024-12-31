import ComposableArchitecture
import Foundation
import ScryfallKit
import Networking

@Reducer
struct Feature {
  @Dependency(\.cardQueryRequestClient) var client
  
  @ObservableState
  struct State: Equatable {
    enum Mode: Equatable {
      case placeholder(numberOfDataSource: Int)
      case data(DataSource)
      
      var isPlaceholder: Bool {
        switch self {
        case .placeholder:
          return true
          
        case .data:
          return false
        }
      }
      
      var dataSource: DataSource {
        switch self {
        case let .placeholder(numberOfDataSource):
          var cards: [Card] = []
          
          for _ in 0...numberOfDataSource {
            cards.append(
              Card(
                id: UUID(),
                oracleId: "1",
                lang: "en",
                printsSearchUri: "",
                rulingsUri: "",
                scryfallUri: "",
                uri: "",
                cmc: 0,
                colorIdentity: [],
                keywords: [],
                layout: .normal,
                legalities: .init(
                  standard: nil,
                  historic: nil,
                  pioneer: nil,
                  modern: nil,
                  legacy: nil,
                  pauper: nil,
                  vintage: nil,
                  penny: nil,
                  commander: nil,
                  brawl: nil
                ),
                name: "",
                oversized: false,
                reserved: false,
                booster: false,
                borderColor: .black,
                collectorNumber: "",
                digital: false,
                finishes: [],
                frame: .future,
                fullArt: false,
                games: [],
                highresImage: false,
                imageStatus: .highresScan,
                imageUris: .init(
                  small: "https://google.com",
                  normal: "https://google.com",
                  large: "https://google.com",
                  png: "https://google.com",
                  artCrop: "https://google.com",
                  borderCrop: "https://google.com"
                ),
                prices: .init(
                  tix: nil,
                  usd: "1",
                  usdFoil: "1",
                  eur: "1"
                ),
                promo: false,
                rarity: .bonus,
                relatedUris: [:],
                releasedAt: "1",
                reprint: false,
                scryfallSetUri: "",
                setName: "",
                setSearchUri: URL.init(
                  string: "https://google.com"
                )!,
                setType: .alchemy,
                setUri: "",
                set: "",
                storySpotlight: false,
                textless: false,
                variation: false
              )
            )
          }
          
          return DataSource(cards: IdentifiedArray(uniqueElements: cards), hasNextPage: false)
          
        case let .data(value):
          return value
        }
      }
    }
    
    var mode: Mode
    var queryType: QueryType
    var selectedCard: Card?
    
    init(
      mode: Mode,
      queryType: QueryType,
      selectedCard: Card?
    ) {
      self.mode = mode
      self.queryType = queryType
      self.selectedCard = selectedCard
    }
  }
  
  enum Action: Equatable {
    case didSelectCard(Card)
    case loadMoreCardsIfNeeded(displayingIndex: Int)
    case updateCards([Card], hasNextPage: Bool, queryType: QueryType)
    case viewAppeared
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didSelectCard(value):
        state.selectedCard = value
        return .none
        
      case let .loadMoreCardsIfNeeded(displayingIndex):
        guard
          displayingIndex == state.mode.dataSource.cards.count - 1,
          state.mode.dataSource.hasNextPage
        else {
          return .none
        }
        
        let nextQuery = state.queryType.next()
        
        return .run { [client] send in
          let result = try await client.queryCards(nextQuery)
          
          await send(
            .updateCards(
              result.data,
              hasNextPage: result.hasMore ?? false,
              queryType: nextQuery
            )
          )
        }
        .cancellable(
          id: "loadMoreCardsIfNeeded: \(displayingIndex), for query: \(state.queryType)",
          cancelInFlight: true
        )
        
      case let .updateCards(value, hasNextPage, nextQuery):
        switch state.mode {
        case var .data(dataSource):
          dataSource.cards.append(contentsOf: value)
          dataSource.hasNextPage = hasNextPage
          state.mode = .data(dataSource)
          state.queryType = nextQuery
          
        case .placeholder:
          state.mode = .data(DataSource(cards: IdentifiedArray(uniqueElements: value), hasNextPage: hasNextPage))
          state.queryType = nextQuery
        }
        
        return .none
        
      case .viewAppeared:
        return .run { [client, queryType = state.queryType] send in
          let result = try await client.queryCards(queryType)
          
          await send(
            .updateCards(
              result.data,
              hasNextPage: result.hasMore ?? false,
              queryType: queryType
            )
          )
        }
        .cancellable(
          id: "viewAppeared: \(state.queryType)",
          cancelInFlight: true
        )
      }
    }
  }
}

extension Feature {
  struct DataSource: Equatable {
    var cards: IdentifiedArrayOf<Card>
    var hasNextPage: Bool
    
    init(cards: IdentifiedArrayOf<Card>, hasNextPage: Bool) {
      self.cards = cards
      self.hasNextPage = hasNextPage
    }
  }
}
