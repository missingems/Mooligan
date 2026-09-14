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

struct PriceHistoryNeedle: View {
  let interaction: ChartInteraction
  let isEnabled: Bool
  let layout: ScrubLayout

  @Environment(\.colorScheme) private var colorScheme

  private static let bendDepth: CGFloat = 18.0

  var body: some View {
    if isEnabled,
       let anchorX = interaction.anchorX,
       let plotTop = interaction.plotTopY,
       let plotBottom = interaction.plotBottomY,
       layout.headerWidth > 0.0,
       layout.readoutSize.width > 0.0 {
      let isScrubbing = interaction.scrubbedDate != nil
      let x = layout.chartOrigin.x + anchorX
      let readout = layout.readoutOrigin(anchorX: anchorX)
      let start = isScrubbing
        ? CGPoint(x: readout.x + layout.readoutSize.width / 2.0, y: readout.y + layout.readoutSize.height)
        : CGPoint(x: x, y: layout.chartOrigin.y + plotTop)
      let end = CGPoint(x: x, y: layout.chartOrigin.y + plotBottom)

      if end.y > start.y {
        NeedleString(
          start: start,
          end: end,
          bendBottom: max(layout.chartOrigin.y, start.y) + Self.bendDepth
        )
        .stroke(
          PriceChartStyle.gridColor(colorScheme),
          style: StrokeStyle(lineWidth: PriceChartStyle.needleWidth, lineCap: .round, lineJoin: .round)
        )
        .opacity(isScrubbing ? 1.0 : 0.0)
        .allowsHitTesting(false)
        .animation(ScrubLayout.slide, value: isScrubbing)
        .transaction { $0.animation = $0.animation == ScrubLayout.slide ? $0.animation : nil }
      }
    }
  }
}

struct NeedleString: Shape {
  var start: CGPoint
  var end: CGPoint
  var bendBottom: CGFloat

  private static let cornerRadius: CGFloat = 13.0

  var animatableData: AnimatablePair<AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData>, CGFloat> {
    get { AnimatablePair(AnimatablePair(start.animatableData, end.animatableData), bendBottom) }
    set {
      start.animatableData = newValue.first.first
      end.animatableData = newValue.first.second
      bendBottom = newValue.second
    }
  }

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
