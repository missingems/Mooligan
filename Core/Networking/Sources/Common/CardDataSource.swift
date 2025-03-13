import ComposableArchitecture
import Foundation
import ScryfallKit

public struct CardDataSource: Equatable {
  public var cardDetails: [CardInfo]
  public var focusedCard: Card?
  public var hasNextPage: Bool
  public var total: Int
  
  public init(
    cards: [Card],
    focusedCard: Card?,
    hasNextPage: Bool,
    total: Int
  ) {
    self.cardDetails = cards.map { card in
      CardInfo(card: card)
    }
    self.focusedCard = focusedCard
    self.hasNextPage = hasNextPage
    self.total = total
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
  
  public init(card: Card) {
    self.card = card
    self.displayableCardImage = DisplayableCardImage(card)
  }
}
