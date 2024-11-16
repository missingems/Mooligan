import Foundation

public struct PurchaseVendor: Equatable, Sendable {
  public struct Link: Equatable, Sendable {
    public let url: URL
    public let label: String
  }
  
  public let tcgPlayer: Link?
  public let cardHoarder: Link?
  public let cardMarket: Link?
  
  
  public init(purchaseURIs: [String: String]?) {
    if let uri = purchaseURIs?["tcgplayer"], let url = URL(string: uri) {
      tcgPlayer = Link(url: url, label: "TCGPlayer")
    } else {
      tcgPlayer = nil
    }
    
    if let uri = purchaseURIs?["cardhoarder"], let url = URL(string: uri) {
      cardHoarder = Link(url: url, label: "Cardhoarder")
    } else {
      cardHoarder = nil
    }
    
    if let uri = purchaseURIs?["cardmarket"], let url = URL(string: uri) {
      cardMarket = Link(url: url, label: "Cardmarket")
    } else {
      cardMarket = nil
    }
  }
}
