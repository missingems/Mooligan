import Foundation
import ScryfallKit

extension Card.Face: MagicCardFace {
  public var magicColorIndicator: [Card.Color] {
    return colorIndicator ?? []
  }
  
  public var magicColors: [Card.Color] {
    return colors ?? []
  }
  
  public var manaValue: Double? {
    return cmc
  }
  
  public func getImageURL() -> URL? {
    guard let uri = imageUris?.normal else {
      return nil
    }
    
    return URL(string: uri)

  }
  
  public func getManaCost() -> String? {
    return manaCost
  }
}
