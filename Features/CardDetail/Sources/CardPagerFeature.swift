import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

@Reducer
public struct CardPagerFeature: Sendable {
  @ObservableState
  public struct State: Equatable {
    public var cards: IdentifiedArrayOf<CardDetailFeature.State>
    public var selectedId: UUID?
    @Presents public var showRulings: RulingFeature.State?
    var rawCardDetails: [CardInfo]
    var queryType: QueryType
    
    public init(cardDetails: [CardInfo], initialSelectedCard: Card, queryType: QueryType) {
      self.rawCardDetails = cardDetails
      self.queryType = queryType
      self.selectedId = initialSelectedCard.id
      
      if let initialInfo = cardDetails.first(where: { $0.card.id == initialSelectedCard.id }) {
        self.cards = [
          CardDetailFeature.State(
            card: initialInfo.card,
            displayableCardImage: initialInfo.displayableCardImage,
            queryType: queryType
          )
        ]
      } else {
        self.cards = []
      }
    }
  }
  
  public enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case cards(IdentifiedActionOf<CardDetailFeature>)
    case showRulings(PresentationAction<RulingFeature.Action>)
    case viewAppeared
    case setRemainingCards(IdentifiedArrayOf<CardDetailFeature.State>)
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
        
      case .viewAppeared:
        guard state.cards.count < state.rawCardDetails.count else { return .none }
        
        let rawDetails = state.rawCardDetails
        let query = state.queryType
        
        return .run { send in
          let mapped = rawDetails.map { info in
            CardDetailFeature.State(
              card: info.card,
              displayableCardImage: info.displayableCardImage,
              queryType: query
            )
          }
          
          await send(.setRemainingCards(IdentifiedArray(uniqueElements: mapped)))
        }
        
      case var .setRemainingCards(fullArray):
        for existingCard in state.cards {
          fullArray[id: existingCard.id] = existingCard
        }
        state.cards = fullArray
        return .none
        
      case let .cards(.element(id: id, action: .viewRulingsTapped)):
        guard let card = state.cards[id: id]?.content.card else {
          return .none
        }
        state.showRulings = RulingFeature.State(card: card, title: "Rulings")
        return .none
        
      case .cards:
        return .none
        
      case .showRulings:
        return .none
      }
    }
    .forEach(\.cards, action: \.cards) {
      CardDetailFeature()
    }
    .ifLet(\.$showRulings, action: \.showRulings) {
      RulingFeature()
    }
    ._printChanges()
  }
  
  public init() {}
}
