import Foundation
import ScryfallKit

extension Card.Face: MagicCardFace {
  public var magicColorIndicator: [Card.Color]? { colorIndicator }
  public var magicColors: [Card.Color]? { colors }
  public var manaValue: Double? { cmc }
  
  public func getImageURL() -> URL? {
    guard let uri = imageUris?.normal else {
      return nil
    }
    
    return URL(string: uri)
  }
  
  public func getArtCroppedImageURL() -> URL? {
    guard let uri = imageUris?.artCrop else {
      return nil
    }
    
    return URL(string: uri)
  }
  
  public func getManaCost() -> String? {
    return manaCost
  }
}
