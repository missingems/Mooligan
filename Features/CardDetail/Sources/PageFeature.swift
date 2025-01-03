import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import SwiftUI

@Reducer public struct PageFeature {
  public var body: some ReducerOf<Self> {
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
  
  public init() {}
}

public extension PageFeature {
  @ObservableState struct State: Equatable {
    var cards: IdentifiedArrayOf<CardDetailFeature.State> = []
    var currentDisplayingCard: Card?
    
    public init(query: QueryType, currentDisplayingCard: Card?) {
      switch query {
      case .search:
        fatalError("Not implemented")
        
      case let .set(set, page):
//        self.cards = IdentifiedArrayOf(
//          uniqueElements: cards.map { card in
//            CardDetailFeature.State(card: card, entryPoint: .set(set))
//          }
//        )
        self.cards = []
      }
      
      self.currentDisplayingCard = currentDisplayingCard
    }
  }
  
  @CasePathable enum Action: BindableAction {
    case binding(BindingAction<State>)
    case cards(IdentifiedActionOf<CardDetailFeature>)
    case addTapped
    case shareTapped
  }
}
