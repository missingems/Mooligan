import ComposableArchitecture
import Foundation
import Networking
import SwiftUI

@Reducer struct PageFeature<Client: MagicCardDetailRequestClient> {
  let client: Client
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .shareTapped:
        return .none
        
      case .addTapped:
        return .none
      case .binding:
        return .none
        
      case .cards:
        return .none
      }
    }
    .forEach(\.cards, action: \.cards) {
      CardDetailFeature(client: client)
    }
  }
  
  init(client: Client) {
    self.client = client
  }
}

extension PageFeature {
  @ObservableState struct State: Equatable {
    var cards: IdentifiedArrayOf<CardDetailFeature<Client>.State> = []
    var currentDisplayingCard: Int? = 0
    
    public init(cards: [Client.MagicCardModel]) {
      self.cards = IdentifiedArrayOf(uniqueElements: cards.map { card in
        CardDetailFeature<Client>.State(card: card, entryPoint: .query)
      })
    }
  }
  
  @CasePathable enum Action: BindableAction {
    case binding(BindingAction<State>)
    case cards(IdentifiedActionOf<CardDetailFeature<Client>>)
    case addTapped
    case shareTapped
  }
}
