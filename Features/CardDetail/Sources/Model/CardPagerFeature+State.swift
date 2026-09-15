import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

extension CardPagerFeature {
  @ObservableState
  public struct State: Equatable {
    public var cards: IdentifiedArrayOf<CardDetailFeature.State>
    public var selectedId: UUID?
    @Presents public var showRulings: RulingFeature.State?
    var rawCardDetails: [CardInfo]
    var queryType: QueryType
    
    public init(cardDetails: [CardInfo], initialSelectedCard: Card, queryType: QueryType) {
      self.rawCardDetails = cardDetails
      self.queryType = queryType
      self.selectedId = initialSelectedCard.id
      
      if let initialInfo = cardDetails.first(where: { $0.card.id == initialSelectedCard.id }) {
        self.cards = [
          CardDetailFeature.State(
            card: initialInfo.card,
            displayableCardImage: initialInfo.displayableCardImage,
            queryType: queryType
          )
        ]
      } else {
        self.cards = []
      }
    }
  }
}
