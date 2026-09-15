import Networking
import SwiftUI

extension CGSize {
  func snapped(to scale: CGFloat) -> CGSize {
    CGSize(width: width.snapped(to: scale), height: height.snapped(to: scale))
  }
}
