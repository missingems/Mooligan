//
//  VariantGalleryFeature.swift
//  CardDetail
//
//  Created by Jun on 26/3/25.
//

import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit

@Reducer public struct VariantGalleryFeature {
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .viewAppeared:
        return .none
      }
    }
  }
  
  public init() {}
}

public extension VariantGalleryFeature {
  @ObservableState struct State: Equatable {
    let selectedCard: Card
    
    public init(selectedCard: Card) {
      self.selectedCard = selectedCard
    }
  }
  
  enum Action: Equatable {
    case viewAppeared
  }
}
