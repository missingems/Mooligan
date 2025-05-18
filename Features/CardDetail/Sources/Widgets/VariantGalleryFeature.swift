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
import SwiftUI

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
    let cardDataSource: CardDataSource
    var selectedCard: Card
    var scrollPosition: ScrollPosition
    public let id: String
    
    public init(cardDataSource: CardDataSource, selectedCard: Card, id: String) {
      self.cardDataSource = cardDataSource
      self.selectedCard = selectedCard
      self.id = id
      self.scrollPosition = .init(id: selectedCard.id)
    }
  }
  
  enum Action: Equatable {
    case viewAppeared
  }
}
