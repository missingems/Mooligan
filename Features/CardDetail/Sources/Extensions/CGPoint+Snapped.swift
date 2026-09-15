import Networking
import SwiftUI

extension CGPoint {
  func snapped(to scale: CGFloat) -> CGPoint {
    CGPoint(x: x.snapped(to: scale), y: y.snapped(to: scale))
  }
}
