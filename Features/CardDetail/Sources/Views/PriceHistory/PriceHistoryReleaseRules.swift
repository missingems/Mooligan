import DesignComponents
import Networking
import SwiftUI

/// A hairline from under each release icon to the bottom of the plot, stronger for the release
/// being scrubbed over.
struct PriceHistoryReleaseRules: View {
  let layout: ReleaseMarkerLayout
  let interaction: ChartInteraction

  @Environment(\.displayScale) private var displayScale

  var body: some View {
    let active = interaction.scrubbedDate == nil ? nil : layout.entry(under: interaction.needleX)
    let width = 1.0 / max(displayScale, 1.0)

    ZStack {
      rules(layout.entries.filter { $0 != active })
        .stroke(Color.primary.opacity(0.16), lineWidth: width)

      if let active {
        rules([active])
          .stroke(Color.primary.opacity(0.45), lineWidth: width)
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func rules(_ entries: [ReleaseMarkerLayout.Entry]) -> Path {
    Path { path in
      guard layout.plot.height > 0.0, layout.ruleTop < layout.plot.maxY else { return }
      for entry in entries {
        path.move(to: CGPoint(x: entry.ruleX, y: layout.ruleTop))
        path.addLine(to: CGPoint(x: entry.ruleX, y: layout.plot.maxY))
      }
    }
  }
}
