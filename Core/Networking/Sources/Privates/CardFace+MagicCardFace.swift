import Foundation
import ScryfallKit

extension Card.Face: MagicCardFace {
  public var magicColorIndicator: [any MagicCardColor]? { colorIndicator }
  public var magicColors: [any MagicCardColor]? { colors }
  public var manaValue: Double? { cmc }
  
  public func getImageURL() -> URL? {
    guard let uri = imageUris?.normal else {
      return nil
    }
    
    return URL(string: uri)
  }
}
