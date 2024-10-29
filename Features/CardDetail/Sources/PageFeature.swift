import ComposableArchitecture
import Foundation
import OSLog
import Networking

@Reducer public struct PageFeature<Client: MagicCardDetailRequestClient> {
  let client: Client
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      }
    }
  }
  
  public init(client: Client) {
    self.client = client
  }
}

public extension PageFeature {
  @ObservableState struct State: Equatable, Sendable {
    @Shared var contentOffset: CGFloat
    var cards: [Client.MagicCardModel] = []
    
    public init(contentOffset: CGFloat, cards: [Client.MagicCardModel]) {
      self._contentOffset = Shared(contentOffset)
      self.cards = cards
    }
  }
  
  enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
  }
}
