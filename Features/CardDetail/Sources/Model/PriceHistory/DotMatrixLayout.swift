import SwiftUI

struct DotMatrixLayout: Equatable {
  static let targetSpacing: CGFloat = 8.0

  let plot: CGRect
  let tickRows: [CGFloat]

  var spacing: CGFloat {
    let sorted = tickRows.sorted()
    guard sorted.count >= 2 else { return Self.targetSpacing }
    let gap = sorted[1] - sorted[0]
    guard gap > 0.0 else { return Self.targetSpacing }
    let divisions = max(1.0, (gap / Self.targetSpacing).rounded())
    return gap / divisions
  }

  func dots() -> [CGPoint] {
    guard plot.width > 0.0, plot.height > 0.0 else { return [] }

    let spacing = spacing
    let anchorY = tickRows.min() ?? plot.minY
    let firstRow = anchorY - ((anchorY - plot.minY) / spacing).rounded(.down) * spacing
    let firstColumn = plot.maxX - (plot.width / spacing).rounded(.down) * spacing

    var dots: [CGPoint] = []
    var y = firstRow
    while y <= plot.maxY + 0.5 {
      var x = firstColumn
      while x <= plot.maxX + 0.5 {
        dots.append(CGPoint(x: x, y: y))
        x += spacing
      }
      y += spacing
    }
    return dots
  }
}
