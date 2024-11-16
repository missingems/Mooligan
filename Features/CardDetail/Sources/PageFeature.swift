import ComposableArchitecture
import Foundation
import Networking

@Reducer struct PageFeature<Client: MagicCardDetailRequestClient> {
  let client: Client
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .cards(value):
        return .none
      }
    }
    .forEach(\.cards, action: \.cards) {
      CardDetailFeature(client: client)
    }
    ._printChanges(.actionLabels)
  }
  
  init(client: Client) {
    self.client = client
  }
}

extension PageFeature {
  @ObservableState struct State: Equatable {
    var cards: IdentifiedArrayOf<CardDetailFeature<Client>.State> = []
    
    public init(cards: [Client.MagicCardModel]) {
      self.cards = IdentifiedArrayOf(uniqueElements: cards.map({ card in
        return CardDetailFeature<Client>.State(card: card, entryPoint: .query)
      }))
    }
  }
  
  @CasePathable enum Action {
    case cards(IdentifiedActionOf<CardDetailFeature<Client>>)
  }
}
