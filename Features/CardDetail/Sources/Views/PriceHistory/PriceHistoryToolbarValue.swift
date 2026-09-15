import SwiftUI

/// The number inside a toolbar capsule, rolling from one value to the next.
struct PriceHistoryToolbarValue: View {
  let text: String
  let isAvailable: Bool

  var body: some View {
    Text(text)
      .fontDesign(.rounded)
      .font(.body)
      .fontWeight(.semibold)
      .monospacedDigit()
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .contentTransition(.numericText())
      .animation(.snappy(duration: 0.2), value: text)
      .foregroundStyle(isAvailable ? .primary : .tertiary)
      .frame(maxWidth: .infinity, minHeight: 34)
      .padding(EdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11))
      .contentShape(.capsule)
  }
}
