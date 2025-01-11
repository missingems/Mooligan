import ComposableArchitecture
import Foundation
import ScryfallKit

public struct QueryDataSource: Equatable {
  public var queryType: QueryType?
  public var cardDetails: [CardInfo]
  public var focusedCard: Card?
  public var hasNextPage: Bool
  
  public init(
    queryType: QueryType?,
    cards: [Card],
    focusedCard: Card?,
    hasNextPage: Bool
  ) {
    self.queryType = queryType
    
    switch queryType {
    case .set:
      self.cardDetails = cards.map { card in
        CardInfo(card: card)
      }
      
    case .search:
      fatalError()
      
    default:
      self.cardDetails = cards.map { card in
        CardInfo(card: card)
      }
    }
    
    self.focusedCard = focusedCard
    self.hasNextPage = hasNextPage
  }
  
  public mutating func append(cards: [Card]) {
    switch queryType {
    case .set:
      cardDetails.append(
        contentsOf: cards.map { card in
          CardInfo(card: card)
        }
      )
      
    case .search:
      fatalError()
      
    default:
      fatalError()
    }
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
