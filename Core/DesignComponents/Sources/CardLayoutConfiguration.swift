import SwiftUI
import Networking

public struct CardLayoutConfiguration: Equatable, Sendable {
  public enum Rotation: Equatable, Sendable {
    case landscape
    case portrait
    
    public var ratio: CGFloat {
      switch self {
      case .landscape:
        return MagicCardImageRatio.heightToWidth.rawValue
        
      case .portrait:
        return MagicCardImageRatio.widthToHeight.rawValue
      }
    }
  }
  
  public let rotation: Rotation
  public let size: CGSize
  public let cornerRadius: CGFloat
  
  public init(rotation: Rotation, maxWidth: CGFloat) {
    self.rotation = rotation
    let imageHeight = (maxWidth / rotation.ratio).rounded()
    size = CGSize(width: maxWidth, height: imageHeight)
    cornerRadius = 5 / 100 * (rotation == .landscape ? size.height : size.width)
  }
}
