import ComposableArchitecture
import Foundation
import Networking

@Reducer struct PageFeature<Client: MagicCardDetailRequestClient> {
  let client: Client
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .cards(value):
        print(value)
        return .none
      }
    }
  }
  
  init(client: Client) {
    self.client = client
  }
}

extension PageFeature {
  @ObservableState struct State: Equatable {
    var cards: IdentifiedArrayOf<Feature<Client>.State> = []
    
    public init(cards: [Client.MagicCardModel]) {
      self.cards = IdentifiedArrayOf(uniqueElements: cards.map({ card in
        return Feature<Client>.State(card: card, entryPoint: .query)
      }))
    }
  }
  
  @CasePathable enum Action {
    case cards(IdentifiedActionOf<Feature<Client>>)
  }
}
