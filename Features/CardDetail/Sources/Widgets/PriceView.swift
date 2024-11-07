import DesignComponents
import Networking
import SwiftUI

struct PriceView: View {
  private let title: String
  private let subtitle: String
  private let models: [Model]
  
  var body: some View {
    Divider()
      .safeAreaPadding(.leading, nil)
    
    VStack(alignment: .leading, spacing: 5.0) {
      Text(title)
        .font(.headline)
      
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
      
      HStack(alignment: .center, spacing: 5.0) {
        ForEach(models) { $0 }
      }
      .padding(.top, 3.0)
    }
    .safeAreaPadding(.horizontal, nil)
    .padding(.vertical, 13.0)
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
        isFoil: false,
        purchaseLinks: [purchaseVendor.tcgPlayer, purchaseVendor.cardMarket].compactMap { $0 }
      ),
      Model(
        action: .didSelectUSDPrice,
        currencySymbol: "$",
        isDisabled: prices.usdFoil == nil,
        label: usdFoilLabel,
        price: prices.usdFoil ?? "0.00",
        isFoil: true,
        purchaseLinks: [purchaseVendor.tcgPlayer, purchaseVendor.cardMarket].compactMap { $0 }
      ),
      Model(
        action: .didSelectUSDPrice,
        isDisabled: prices.tix == nil,
        label: tixLabel,
        price: prices.tix ?? "0.00",
        isFoil: false,
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
    let isFoil: Bool
    let purchaseLinks: [PurchaseVendor.Link]
    
    init(
      action: Action,
      currencySymbol: String = "",
      isDisabled: Bool,
      label: String,
      price: String,
      isFoil: Bool,
      purchaseLinks: [PurchaseVendor.Link]
    ) {
      self.action = action
      self.currencySymbol = currencySymbol
      self.isDisabled = isDisabled
      self.label = label
      self.price = price
      self.isFoil = isFoil
      self.purchaseLinks = purchaseLinks
    }
    
    var body: some View {
      VStack(spacing: 3.0) {
        Menu {
          ForEach(purchaseLinks) { destination in
            Link(destination: destination.url) {
              Image(systemName: "link").imageScale(.small)
              Text(destination.label)
            }
          }
        } label: {
          Text("\(currencySymbol)\(price)")
            .font(.body)
            .fontWeight(isDisabled ? .regular : .semibold)
            .foregroundStyle((isFoil && isDisabled == false ) ? DesignComponentsAsset.accentColorDark.swiftUIColor : DesignComponentsAsset.accentColor.swiftUIColor)
            .monospaced()
            .frame(maxWidth: .infinity, minHeight: 34)
            .padding(.vertical, 5.0)
            .background {
              if isFoil, isDisabled == false {
                LinearGradient(
                  colors: [Color(#colorLiteral(red: 0.9725449681, green: 0.8013705611, blue: 0.4944624901, alpha: 1)), Color(#colorLiteral(red: 0.9137322307, green: 0.9137201905, blue: 0.5514469147, alpha: 1)), Color(#colorLiteral(red: 0.5428386331, green: 0.8030003309, blue: 0.5898079276, alpha: 1)), Color(#colorLiteral(red: 0.5428386331, green: 0.8030003309, blue: 0.5898079276, alpha: 1)), Color(#colorLiteral(red: 0.6374309659, green: 0.8531000018, blue: 0.875569284, alpha: 1)), Color(#colorLiteral(red: 0.5439324379, green: 0.6502383351, blue: 0.7930879593, alpha: 1)), Color(#colorLiteral(red: 0.4611749649, green: 0.5113767385, blue: 0.7011086941, alpha: 1))],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              } else {
                Color(.systemFill)
              }
            }
            .clipShape(RoundedRectangle(cornerRadius: 13.0))
        }
        .buttonStyle(.sinkableButtonStyle)
        
        Text(label)
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxHeight: .infinity, alignment: .center)
      }
      .disabled(isDisabled)
      .opacity(isDisabled ? 0.31 : 1.0)
    }
  }
}
