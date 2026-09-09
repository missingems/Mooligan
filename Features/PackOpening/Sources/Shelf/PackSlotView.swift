import DesignComponents
import Networking
import SwiftUI

/// One pack in the grid: the art, and its set code and price underneath.
struct PackSlotView: View {
  let product: PackProduct
  let isDispensing: Bool
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      VStack(spacing: 6) {
        BoosterPackView(product: product)
          .opacity(isDispensing ? 0 : 1)

        label
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.sinkableButtonStyle)
    .disabled(isDispensing)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(product.set.name), \(product.kind.title)")
    .accessibilityHint("Opens a pack")
    .accessibilityAddTraits(.isButton)
    .accessibilityIdentifier("packOpening.slot.\(product.id)")
  }

  private var label: some View {
    VStack(spacing: 1) {
      Text(product.setCode)
        .font(.caption.weight(.semibold))

      Text(product.kind.title)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .lineLimit(1)
  }
}
