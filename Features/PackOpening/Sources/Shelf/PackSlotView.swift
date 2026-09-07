import DesignComponents
import Networking
import SwiftUI

/// One pack standing on a shelf, with its price label and its reflection in the
/// shelf glass.
///
/// `width` is passed in rather than inferred: the reflection is a mirrored copy
/// cropped to a sliver, and cropping needs the pack's real size.
struct PackSlotView: View {
  let product: PackProduct
  let width: CGFloat
  let isDispensing: Bool
  let onSelect: () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var height: CGFloat { width / PackGeometry.widthToHeight }
  private var reflectionHeight: CGFloat { min(30, height * 0.22) }

  var body: some View {
    Button(action: onSelect) {
      VStack(spacing: 0) {
        pack
        reflection
        label
      }
      .frame(width: width)
    }
    .buttonStyle(.sinkableButtonStyle)
    .disabled(isDispensing)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(product.set.name), \(product.kind.title), \(product.kind.priceLabel)")
    .accessibilityHint("Opens a pack")
    .accessibilityAddTraits(.isButton)
    .accessibilityIdentifier("packOpening.slot.\(product.id)")
  }

  private var pack: some View {
    BoosterPackView(product: product, shadowRadius: 10)
      .frame(width: width, height: height)
      // Leaning back against the rail, then dropped into the tray when the
      // machine dispenses it.
      .rotation3DEffect(
        .degrees(reduceMotion ? 0 : 7),
        axis: (x: 1, y: 0, z: 0),
        anchor: .bottom,
        perspective: 0.5
      )
      .offset(y: isDispensing ? height * 0.35 : 0)
      .scaleEffect(isDispensing ? 0.82 : 1, anchor: .bottom)
      .opacity(isDispensing ? 0 : 1)
      .animation(.spring(duration: 0.32, bounce: 0.12), value: isDispensing)
  }

  private var reflection: some View {
    BoosterPackView(product: product, shadowRadius: 0)
      .frame(width: width, height: height)
      .scaleEffect(y: -1)
      .frame(height: reflectionHeight, alignment: .top)
      .clipped()
      .mask {
        LinearGradient(
          colors: [.black.opacity(0.3), .clear],
          startPoint: .top,
          endPoint: .bottom
        )
      }
      .opacity(isDispensing ? 0 : 1)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }

  private var label: some View {
    VStack(spacing: 1) {
      Text(product.setCode)
        .font(.caption2.weight(.bold))
        .fontWidth(.condensed)
        .foregroundStyle(.white.opacity(0.9))

      Text(product.kind.priceLabel)
        .font(.system(size: 9, weight: .semibold, design: .monospaced))
        .foregroundStyle(VendingMachineChrome.neon.opacity(0.85))
    }
    .padding(.top, 6)
    .lineLimit(1)
  }
}
