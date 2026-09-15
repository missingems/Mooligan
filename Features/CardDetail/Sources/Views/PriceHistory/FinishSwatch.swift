import Networking
import SwiftUI

struct FinishSwatch: View {
  let kind: PriceSeriesKind

  var body: some View {
    Circle()
      .fill(PriceChartStyle.color(for: kind))
      .frame(width: PriceChartStyle.swatchSize, height: PriceChartStyle.swatchSize)
  }
}
