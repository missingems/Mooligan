import Foundation

public enum MagicCardImageRatio: CGFloat {
  /// 0.7179487179
  case widthToHeight = 0.7179487179
  
  /// 1.3928571428
  case heightToWidth = 1.3928571428
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
