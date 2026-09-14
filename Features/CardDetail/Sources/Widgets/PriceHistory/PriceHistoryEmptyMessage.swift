import SwiftUI

struct PriceHistoryEmptyMessage: View {
  enum Reason: Equatable {
    case unavailable
    case failed
  }

  let reason: Reason
  let labels: PriceHistoryLabels
  let onRetry: () -> Void

  var body: some View {
    switch reason {
    case .unavailable:
      Text(labels.unavailable)
        .font(.title)
        .foregroundStyle(.secondary)
        .allowsHitTesting(false)

    case .failed:
      VStack(spacing: 13.0) {
        Text(labels.failed)
          .font(.title)
          .foregroundStyle(.secondary)

        GlassCapsuleAction(title: labels.retry, accessibilityID: "priceHistory.retry", action: onRetry)
      }
    }
  }
}
