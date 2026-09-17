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
