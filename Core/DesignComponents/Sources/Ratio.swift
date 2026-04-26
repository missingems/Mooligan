import Foundation

public enum MagicCardImageRatio: CGFloat {
  case widthToHeight = 0.715909
  case heightToWidth = 1.396825
}

extension CGFloat {
  public func multiplied(byRatio ratio: MagicCardImageRatio, rounded: Bool = true) -> CGFloat  {
    if rounded {
      return (self * ratio.rawValue).rounded()
    } else {
      return (self * ratio.rawValue)
    }
  }
}
