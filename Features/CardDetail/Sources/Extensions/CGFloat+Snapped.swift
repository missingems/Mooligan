import Networking
import SwiftUI

extension CGFloat {
  func snapped(to scale: CGFloat) -> CGFloat {
    guard scale > 0.0, isFinite else { return self }
    return (self * scale).rounded() / scale
  }
}
