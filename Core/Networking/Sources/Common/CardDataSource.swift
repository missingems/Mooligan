import ComposableArchitecture
import Foundation
import ScryfallKit

public struct CardDataSource: Equatable, Sendable {
  public var cardDetails: [CardInfo]
  public var hasNextPage: Bool
  public var total: Int
  
  public init(
    cards: [Card],
    hasNextPage: Bool,
    total: Int
  ) {
    self.cardDetails = cards.map { card in
      CardInfo(card: card)
    }
    
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

public struct CardInfo: Equatable, Sendable, Identifiable {
  public let card: Card
  public let displayableCardImage: DisplayableCardImage?
  
  public var id: UUID
  public let formattedSetName: String
  public let formattedSetCode: String
  public let formattedCollectorNumber: String
  public let cachedIconURL: URL?
  
  public let displayPriceUSD: String?
  public let displayPriceUSDFoil: String?
  public let displayPriceUSDEtched: String?
  
  public init(card: Card) {
    self.card = card
    self.displayableCardImage = DisplayableCardImage(card)
    
    self.formattedSetName = card.setName
    self.formattedSetCode = card.set.uppercased()
    self.formattedCollectorNumber = "#\(card.collectorNumber.uppercased())"
    self.cachedIconURL = card.resolvedIconURL
    
    self.displayPriceUSD = card.prices.usd != nil ? "$\(card.prices.usd!)" : nil
    self.displayPriceUSDFoil = card.prices.usdFoil != nil ? "$\(card.prices.usdFoil!)" : nil
    self.displayPriceUSDEtched = card.prices.usdEtched != nil ? "$\(card.prices.usdEtched!)" : nil
    self.id = card.id
  }
}
