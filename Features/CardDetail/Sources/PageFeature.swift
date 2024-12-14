import ComposableArchitecture
import Foundation
import Networking
import SwiftUI

@Reducer struct PageFeature<Client: MagicCardDetailRequestClient> {
  let client: Client
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .cards(.element(_, .scrollViewDidScroll(position))):
        state.navigationBarBackgroundVisibility = position > -100.333333 ? .visible : .hidden
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
    var navigationBarBackgroundVisibility: Visibility = .hidden
    var cards: IdentifiedArrayOf<CardDetailFeature<Client>.State> = []
    
    public init(cards: [Client.MagicCardModel]) {
      self.cards = IdentifiedArrayOf(uniqueElements: cards.map { card in
        CardDetailFeature<Client>.State(card: card, entryPoint: .query)
      })
    }
  }
  
  @CasePathable enum Action {
    case cards(IdentifiedActionOf<CardDetailFeature<Client>>)
  }
}
