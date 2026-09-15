import SwiftUI

struct NeedleString: Shape {
  var start: CGPoint
  var end: CGPoint
  var bendBottom: CGFloat

  private static let cornerRadius: CGFloat = 13.0

  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: start)

      let dx = end.x - start.x
      let bottom = min(bendBottom, end.y)
      let rise = bottom - start.y
      guard abs(dx) > 0.5, rise > 0.0 else {
        path.addLine(to: end)
        return
      }

      let midY = start.y + rise / 2.0
      let radius = min(Self.cornerRadius, abs(dx) / 2.0, rise / 2.0)
      let step = dx > 0 ? radius : -radius

      path.addLine(to: CGPoint(x: start.x, y: midY - radius))
      path.addQuadCurve(
        to: CGPoint(x: start.x + step, y: midY),
        control: CGPoint(x: start.x, y: midY)
      )
      path.addLine(to: CGPoint(x: end.x - step, y: midY))
      path.addQuadCurve(
        to: CGPoint(x: end.x, y: midY + radius),
        control: CGPoint(x: end.x, y: midY)
      )
      path.addLine(to: end)
    }
  }
}
