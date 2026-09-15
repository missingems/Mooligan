import SwiftUI

struct ScrubLayout: Equatable {
  static let slide: Animation = .snappy(duration: 0.24)
  static let space = "PriceHistory"

  var headerWidth: CGFloat = 0.0
  var summaryFrame: CGRect = .zero
  var readoutSize: CGSize = .zero
  var chartOrigin: CGPoint = .zero

  func readoutOrigin(anchorX: CGFloat?) -> CGPoint {
    let travel = max(headerWidth - readoutSize.width, 0.0)
    guard let anchorX, readoutSize.width > 0.0 else { return CGPoint(x: travel, y: summaryFrame.minY) }
    let x = min(max(chartOrigin.x + anchorX - readoutSize.width / 2.0, 0.0), travel)
    return CGPoint(x: x, y: summaryFrame.minY)
  }
}
