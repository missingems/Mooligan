import ComposableArchitecture
import Foundation
import Networking

@Reducer public struct RulingFeature: Sendable{
  @Dependency(\.cardDetailRequestClient) var client
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .fetchRulings:
        return .run { [card = state.card] send in
          let rulings = try await client.getRulings(of: card)
          await send(.updateRulings(rulings))
        }
        
      case let .updateRulings(rulings):
        state.mode = .loaded(rulings)
        return .none
        
      case .dismissTapped:
        return .none
      }
    }
  }
}
