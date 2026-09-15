import ComposableArchitecture
import Networking
import SwiftUI

@Reducer
public struct CardPagerFeature: Sendable {
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
        
        return .run(priority: .background) { send in
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
  }
  
  public init() {}
}
