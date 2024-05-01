import Foundation
import ScryfallKit

extension MTGSet: Set {
  public var id: String {
    code
  }
  
  public var numberOfCards: Int {
    cardCount
  }
  
  public var iconURL: URL? {
    URL(string: iconSvgUri)
  }
}
