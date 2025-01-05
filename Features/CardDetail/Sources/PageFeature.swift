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
    @Shared var dataSource: QueryDataSource
    var scrollPosition = ScrollPosition(idType: Card.self)
    
    public init(dataSource: Shared<QueryDataSource>) {
      self._dataSource = dataSource
      
      cards = IdentifiedArray(uniqueElements: dataSource.cardDetails.wrappedValue.map { cardDetail in
        CardDetailFeature.State(card: cardDetail.card, queryType: dataSource.queryType.wrappedValue)
      })
      
      scrollPosition = ScrollPosition(id: dataSource.focusedCard.wrappedValue)
    }
  }
  
  @CasePathable enum Action: BindableAction {
    case binding(BindingAction<State>)
    case cards(IdentifiedActionOf<CardDetailFeature>)
    case addTapped
    case shareTapped
  }
}
