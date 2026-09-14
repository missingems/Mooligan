import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryPurchaseLinksView: View {
  let state: PurchaseDropdownState
  let labels: PriceHistoryLabels
  let onRetry: () -> Void
  let onSelect: (PurchaseVendorGroup.Offer) -> Void
  var glass: (id: String, namespace: Namespace.ID)?

  private static let width: CGFloat = 250.0

  var body: some View {
    VStack(alignment: .leading, spacing: 0.0) {
      switch state {
      case .loading:
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding(.vertical, 21.0)

      case let .loaded(groups) where groups.isEmpty:
        message(labels.purchaseLinksEmpty)

      case let .loaded(groups):
        ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
          if index > 0 {
            VibrantDivider()
              .padding(.vertical, 5.0)
          }

          vendor(group)
        }

      case .failed:
        VStack(spacing: 8.0) {
          message(labels.purchaseLinksFailed)

          GlassCapsuleAction(title: labels.retry, accessibilityID: "priceHistory.purchaseLinks.retry", action: onRetry)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 13.0)
      }
    }
    .padding(.vertical, 8.0)
    .frame(width: Self.width)
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: PriceChartStyle.cardCornerRadius))
    .modifier(GlassIdentity(glass: glass))
  }

  private func vendor(_ group: PurchaseVendorGroup) -> some View {
    VStack(alignment: .leading, spacing: 0.0) {
      Text(group.provider.displayName)
        .font(.subheadline)
        .fontWeight(.semibold)
        .padding(.horizontal, 16.0)
        .padding(.top, 5.0)
        .padding(.bottom, 2.0)
        .accessibilityAddTraits(.isHeader)

      ForEach(group.offers) { offer in
        row(offer)
          .onTapGesture { onSelect(offer) }
          .accessibilityElement(children: .combine)
          .accessibilityAddTraits(.isButton)
          .accessibilityAction { onSelect(offer) }
          .accessibilityIdentifier("priceHistory.purchaseLink.\(offer.id)")
      }
    }
  }

  private func row(_ offer: PurchaseVendorGroup.Offer) -> some View {
    HStack(spacing: 8.0) {
      HStack(spacing: 5.0) {
        if let finish = offer.finish {
          FinishSwatch(kind: finish)
        }

        Text(offer.finishLabel ?? labels.allFinishes)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 8.0)

      if let priceText = offer.priceText {
        Text(priceText)
          .monospaced()
      }

      Image(systemName: "arrow.up.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }
    .lineLimit(1)
    .padding(.horizontal, 16.0)
    .padding(.vertical, 6.0)
    .contentShape(.rect)
  }

  private func message(_ text: String) -> some View {
    Text(text)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 21.0)
  }
}

private struct GlassIdentity: ViewModifier {
  let glass: (id: String, namespace: Namespace.ID)?

  func body(content: Self.Content) -> some View {
    if let glass {
      content.glassEffectID(glass.id, in: glass.namespace)
    } else {
      content
    }
  }
}
