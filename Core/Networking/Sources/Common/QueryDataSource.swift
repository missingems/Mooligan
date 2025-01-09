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
    case let .set(set, page):
      self.cardDetails = cards.map { card in
        CardInfo(card: card, set: set)
      }
      
    case .search:
      fatalError()
      
    default:
      self.cardDetails = cards.map { card in
        CardInfo(card: card, set: nil)
      }
    }
    
    self.focusedCard = focusedCard
    self.hasNextPage = hasNextPage
  }
  
  public mutating func append(cards: [Card]) {
    switch queryType {
    case let .set(set, page):
      let cardDetails = cards.map { card in
        CardInfo(card: card, set: set)
      }
      
      self.cardDetails.append(contentsOf: cardDetails)
      
    case .search:
      fatalError()
      
    default:
      fatalError()
    }
  }
}

public struct CardInfo: Equatable, Identifiable {
  public var card: Card
  public var set: MTGSet?
  
  public var id: UUID {
    return card.id
  }
}
