import Networking
import SwiftUI

struct FinishSwatch: View {
  let kind: PriceSeriesKind
  var isAvailable: Bool = true

  var body: some View {
    Circle()
      .fill(isAvailable ? AnyShapeStyle(PriceChartStyle.color(for: kind)) : AnyShapeStyle(PriceChartStyle.disabled))
      .frame(width: PriceChartStyle.swatchSize, height: PriceChartStyle.swatchSize)
  }
}
