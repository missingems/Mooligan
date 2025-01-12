import ComposableArchitecture
import Foundation
import ScryfallKit

public struct QueryDataSource: Equatable {
  public var cardDetails: [CardInfo]
  public var focusedCard: Card?
  public var hasNextPage: Bool
  
  public init(
    cards: [Card],
    focusedCard: Card?,
    hasNextPage: Bool
  ) {
    self.cardDetails = cards.map { card in
      CardInfo(card: card)
    }
    self.focusedCard = focusedCard
    self.hasNextPage = hasNextPage
  }
  
  public mutating func append(cards: [Card]) {
    cardDetails.append(
      contentsOf: cards.map { card in
        CardInfo(card: card)
      }
    )
  }
}

public struct CardInfo: Equatable {
  public let card: Card
  public let displayableCardImage: DisplayableCardImage
  
  init(card: Card) {
    self.card = card
    self.displayableCardImage = DisplayableCardImage(card)
  }
}
