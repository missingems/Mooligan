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

    /// Every card's state is built here, so the pager opens with its whole collection. Built off
    /// the main thread by the caller (the root prepares it in an effect before pushing). Opening
    /// with only the selected card and filling the rest in afterwards replaced the collection under
    /// the page on show, which gave that page a new identity and built it, chart and all, twice.
    public init(cardDetails: [CardInfo], initialSelectedCard: Card, queryType: QueryType) {
      self.selectedId = initialSelectedCard.id
      self.cards = IdentifiedArray(uniqueElements: cardDetails.map { info in
        CardDetailFeature.State(
          card: info.card,
          displayableCardImage: info.displayableCardImage,
          queryType: queryType
        )
      })
    }
  }
}
