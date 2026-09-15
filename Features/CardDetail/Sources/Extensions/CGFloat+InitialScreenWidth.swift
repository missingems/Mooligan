import DesignComponents
import Networking
import SwiftUI

extension CGFloat {
  @MainActor static var initialScreenWidth: CGFloat {
    UIApplication.shared.connectedScenes
      .lazy
      .compactMap { $0 as? UIWindowScene }
      .first?
      .screen.bounds.width ?? 0
  }
}
