import ComposableArchitecture
import Foundation
import ScryfallKit

public struct CardDataSource: Equatable {
  public var cardDetails: [CardInfo]
  public var hasNextPage: Bool
  public var total: Int
  public let cardPrefixIdentifier: String?
  
  public init(
    cards: [Card],
    hasNextPage: Bool,
    total: Int,
    cardPrefixIdentifier: String?
  ) {
    self.cardPrefixIdentifier = cardPrefixIdentifier
    
    self.cardDetails = cards.map { card in
      CardInfo(card: card, prefixIdentifier: cardPrefixIdentifier)
    }
    
    self.hasNextPage = hasNextPage
    self.total = total
  }
  
  public mutating func append(cards: [Card]) {
    cardDetails.append(
      contentsOf: cards.map { card in
        CardInfo(card: card, prefixIdentifier: cardPrefixIdentifier)
      }
    )
  }
}

public struct CardInfo: Equatable {
  public let card: Card
  public let displayableCardImage: DisplayableCardImage
  
  public init(card: Card, prefixIdentifier: String?) {
    self.card = card
    self.displayableCardImage = DisplayableCardImage(card, prefixIdentifier: prefixIdentifier)
  }
}
