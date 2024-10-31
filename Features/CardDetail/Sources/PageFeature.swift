import ComposableArchitecture
import Foundation
import OSLog
import Networking

@Reducer public struct PageFeature<Client: MagicCardDetailRequestClient> {
  let client: Client
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      }
    }
  }
  
  public init(client: Client) {
    self.client = client
  }
}

public extension PageFeature {
  @ObservableState struct State: Equatable, Sendable {
    var shouldDisplayNavigationBar = false
    var cards: [Client.MagicCardModel] = []
    
    public init(contentOffset: CGFloat, cards: [Client.MagicCardModel]) {
      self.cards = cards
    }
  }
  
  enum Action: Equatable, Sendable {
  }
}
