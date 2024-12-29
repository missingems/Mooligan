import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import SwiftUI

@Reducer struct PageFeature {
  var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .addTapped:
        return .none
        
      case .binding:
        return .none
        
      case .cards:
        return .none
        
      case .shareTapped:
        return .none
      }
    }
    .forEach(\.cards, action: \.cards) {
      CardDetailFeature()
    }
  }
}

extension PageFeature {
  @ObservableState struct State: Equatable {
    var cards: IdentifiedArrayOf<CardDetailFeature.State> = []
    var currentDisplayingCard: Int? = 0
    
    public init(cards: [Card]) {
      self.cards = IdentifiedArrayOf(
        uniqueElements: cards.map { card in
          CardDetailFeature.State(card: card, entryPoint: .query)
        }
      )
    }
  }
  
  @CasePathable enum Action: BindableAction {
    case binding(BindingAction<State>)
    case cards(IdentifiedActionOf<CardDetailFeature>)
    case addTapped
    case shareTapped
  }
}
