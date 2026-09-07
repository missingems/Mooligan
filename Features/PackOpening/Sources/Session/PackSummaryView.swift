import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

/// Everything the pack contained, laid out.
struct PackSummaryView: View {
  let pack: BoosterPack
  let onOpenAnother: () -> Void
  let onDone: () -> Void

  private let columns = [GridItem(.adaptive(minimum: 92, maximum: 130), spacing: 12)]

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        headline

        LazyVGrid(columns: columns, spacing: 14) {
          ForEach(pack.cards) { pulled in
            SummaryCardCell(pulled: pulled)
          }
        }
        .padding(.horizontal, 16)

        actions
      }
      .padding(.vertical, 24)
    }
    .scrollBounceBehavior(.basedOnSize)
    .accessibilityIdentifier("packOpening.summary")
  }

  private var headline: some View {
    VStack(spacing: 8) {
      Text(pack.product.set.name)
        .font(.title3.weight(.semibold))
        .multilineTextAlignment(.center)

      Text(pack.product.kind.title.uppercased())
        .font(.caption.weight(.bold))
        .fontWidth(.condensed)
        .tracking(1.4)
        .foregroundStyle(.secondary)

      HStack(spacing: 18) {
        stat(
          title: String(localized: "Pack Value"),
          value: pack.totalValue.formatted(.currency(code: "USD"))
        )

        if let best = pack.bestPull {
          stat(title: String(localized: "Best Pull"), value: best.card.name)
        }
      }
      .padding(.top, 4)
    }
    .padding(.horizontal, 24)
  }

  private func stat(title: String, value: String) -> some View {
    VStack(spacing: 2) {
      Text(title)
        .font(.caption2.weight(.medium))
        .foregroundStyle(.secondary)
      Text(value)
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
    .frame(maxWidth: .infinity)
  }

  private var actions: some View {
    VStack(spacing: 10) {
      Button(action: onOpenAnother) {
        Label("Open Another", systemImage: "arrow.clockwise")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .accessibilityIdentifier("packOpening.openAnother")

      Button("Back to the Machine", action: onDone)
        .buttonStyle(.bordered)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("packOpening.done")
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
  }
}

private struct SummaryCardCell: View {
  let pulled: PulledCard

  @State private var isImageLoaded = false

  var body: some View {
    VStack(spacing: 6) {
      Group {
        if let url = pulled.card.getImageURL(types: [.normal, .small]) {
          CardRemoteImageView(
            url: url,
            isLandscape: pulled.card.isLandscape,
            id: pulled.id.uuidString,
            isImageLoaded: $isImageLoaded
          )
        } else {
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.primary.opacity(0.12))
            .aspectRatio(MagicCardImageRatio.widthToHeight.rawValue, contentMode: .fit)
        }
      }
      .modifier(FoilFinish(isFoil: pulled.isFoil))
      .overlay(alignment: .topTrailing) {
        if pulled.isFoil {
          Image(systemName: "sparkles")
            .font(.caption2)
            .padding(4)
            .background(.ultraThinMaterial, in: Circle())
            .padding(4)
        }
      }

      HStack(spacing: 4) {
        Circle()
          .fill(pulled.rarity.revealGlow)
          .frame(width: 6, height: 6)

        if let price = pulled.price, price > 0 {
          Text(price, format: .currency(code: "USD"))
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
        } else {
          Text(pulled.rarity.displayName)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .lineLimit(1)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(pulled.card.name), \(pulled.rarity.displayName)\(pulled.isFoil ? ", foil" : "")"
    )
  }
}
