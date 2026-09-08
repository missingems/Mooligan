import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

/// Where to buy the card on screen, and what each storefront is asking.
///
/// Replaces the old "Market Prices" widget. That one showed three price tiles
/// that were all TCGplayer's — the same number the chart above already plots —
/// and hid the vendor links inside a menu on each tile. Splitting by marketplace
/// instead puts a distinct number on every row and makes the link the row.
struct PurchaseLinksView: View {
  private let title: String
  private let subtitle: String
  private let listings: [MarketplaceListing]
  private let finishLabel: (PriceSeriesKind) -> String

  init(
    title: String,
    subtitle: String,
    listings: [MarketplaceListing],
    finishLabel: @escaping (PriceSeriesKind) -> String
  ) {
    self.title = title
    self.subtitle = subtitle
    self.listings = listings
    self.finishLabel = finishLabel
  }

  var body: some View {
    if listings.isEmpty == false {
      VibrantDivider()
        .safeAreaPadding(.leading, systemHorizontalMargin)

      VStack(alignment: .leading, spacing: 5.0) {
        Text(title)
          .font(.headline)

        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)

        VStack(spacing: 0.0) {
          ForEach(Array(listings.enumerated()), id: \.element.id) { index, listing in
            if index > 0 {
              Divider().padding(.leading, 13.0)
            }
            row(for: listing)
          }
        }
        // Same fill and radius as the Information tiles and the chart's box.
        .background(Color(.systemFill))
        .clipShape(RoundedRectangle(cornerRadius: 13.0))
        .padding(.top, 5.0)
      }
      .padding(.horizontal, systemHorizontalMargin)
      .padding(.vertical, 13.0)
    }
  }

  private func row(for listing: MarketplaceListing) -> some View {
    Link(destination: listing.url) {
      HStack(alignment: .center, spacing: 11.0) {
        VStack(alignment: .leading, spacing: 2.0) {
          Text(listing.marketplace.displayName)
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(.primary)

          // The finish breakdown that the old three-tile widget carried, folded
          // onto one line because most cards quote one or two of them.
          Text(priceSummary(for: listing))
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 8.0)

        Image(systemName: "arrow.up.right")
          .font(.footnote)
          .fontWeight(.semibold)
          .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
      }
      .padding(.horizontal, 13.0)
      .padding(.vertical, 11.0)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      Text("\(listing.marketplace.displayName), \(priceSummary(for: listing))")
    )
  }

  private func priceSummary(for listing: MarketplaceListing) -> String {
    listing.orderedPrices
      .map { entry in
        let amount = formatted(entry.amount, for: listing)
        // A single-finish card needs no "Regular" qualifier; the row is the price.
        return listing.orderedPrices.count == 1
          ? amount
          : "\(finishLabel(entry.kind)) \(amount)"
      }
      .joined(separator: "   ")
  }

  /// MTGO event tickets are not a currency, so they get a plain number and a
  /// suffix rather than a currency style that would render them as dollars.
  private func formatted(_ amount: Decimal, for listing: MarketplaceListing) -> String {
    guard listing.isTickets == false else {
      return "\(amount.formatted(.number.precision(.fractionLength(2)))) tix"
    }
    return amount.formatted(.currency(code: listing.marketplace.currencyCode))
  }
}
