import Networking
import SwiftUI

struct PriceView: View {
  private let title: String
  private let subtitle: String
  private let models: [Model]
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.headline)
      
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
      
      HStack(alignment: .center, spacing: 5.0) {
        ForEach(models) { $0 }
      }
    }
    .safeAreaPadding(.horizontal, nil)
  }
  
  init(
    title: String,
    subtitle: String,
    prices: any MagicCardPrices,
    usdLabel: String,
    usdFoilLabel: String,
    tixLabel: String,
    purchaseVendor: PurchaseVendor
  ) {
    self.title = title
    self.subtitle = subtitle
    
    models = [
      Model(
        action: .didSelectUSDPrice,
        currencySymbol: "$",
        isDisabled: prices.usd == nil,
        label: usdLabel,
        price: prices.usd ?? "0.00",
        purchaseLinks: [purchaseVendor.tcgPlayer, purchaseVendor.cardMarket].compactMap { $0 }
      ),
      Model(
        action: .didSelectUSDPrice,
        currencySymbol: "$",
        isDisabled: prices.usdFoil == nil,
        label: usdFoilLabel,
        price: prices.usdFoil ?? "0.00",
        purchaseLinks: [purchaseVendor.tcgPlayer, purchaseVendor.cardMarket].compactMap { $0 }
      ),
      Model(
        action: .didSelectUSDPrice,
        isDisabled: prices.tix == nil,
        label: tixLabel,
        price: prices.tix ?? "0.00",
        purchaseLinks: [purchaseVendor.cardHoarder].compactMap { $0 }
      ),
    ]
  }
}

extension PriceView {
  enum Action: Sendable, Equatable {
    case didSelectUSDPrice
    case didSelectUSDFoilPrice
    case didSelectTixPrice
  }
  
  private struct Model: View, Identifiable {
    let id = UUID()
    let action: Action
    let currencySymbol: String
    let isDisabled: Bool
    let label: String
    let price: String
    let purchaseLinks: [PurchaseVendor.Link]
    
    init(
      action: Action,
      currencySymbol: String = "",
      isDisabled: Bool,
      label: String,
      price: String,
      purchaseLinks: [PurchaseVendor.Link]
    ) {
      self.action = action
      self.currencySymbol = currencySymbol
      self.isDisabled = isDisabled
      self.label = label
      self.price = price
      self.purchaseLinks = purchaseLinks
    }
    
    var body: some View {
      Menu {
        ForEach(purchaseLinks) { destination in
          Link(destination: destination.url) {
            Image(systemName: "link").imageScale(.small)
            Text(destination.label)
          }
        }
      } label: {
        VStack(spacing: 0) {
          Text("\(currencySymbol)\(price)")
            .font(.body)
            .fontWeight(isDisabled ? .regular : .semibold)
            .foregroundStyle(Color.accentColor)
            .monospaced()
          
          Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8.0)
        .background(Color(.systemFill))
      }
      .clipShape(.buttonBorder)
      .buttonStyle(.sinkableButtonStyle)
      .disabled(isDisabled)
      .opacity(isDisabled ? 0.31 : 1.0)
    }
  }
}

#Preview {
  PriceView(
    title: "Market Prices",
    subtitle: "Data from Scryfall",
    prices: MagicCardFixtures.split.value.getPrices(),
    usdLabel: "USD",
    usdFoilLabel: "USD - Foil",
    tixLabel: "Tix",
    purchaseVendor: PurchaseVendor(purchaseURIs: [:])
  )
}
