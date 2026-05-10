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
    @Presents var showRulings: RulingFeature.State?
    
    public init(cards: [Card], initialSelectedCard: Card, queryType: QueryType) {
      self.cards = IdentifiedArray(
        uniqueElements: cards.map {
          CardDetailFeature.State(card: $0, queryType: queryType)
        }
      )
      self.selectedId = initialSelectedCard.id
    }
  }
  
  public enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case cards(IdentifiedActionOf<CardDetailFeature>)
    case showRulings(PresentationAction<RulingFeature.Action>)
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
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
  }
  
  public init() {}
}
