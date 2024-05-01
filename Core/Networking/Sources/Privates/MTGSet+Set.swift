import Foundation
import ScryfallKit

extension MTGSet: GameSet {
  public var numberOfCards: Int {
    cardCount
  }
  
  public var isParent: Bool? {
    parentSetCode == nil
  }
  
  public var iconURL: URL? {
    URL(string: iconSvgUri)
  }
}
