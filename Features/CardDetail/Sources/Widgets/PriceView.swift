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
    sender: @escaping (Action) -> Void
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
        sender: sender
      ),
      Model(
        action: .didSelectUSDPrice,
        currencySymbol: "$",
        isDisabled: prices.usdFoil == nil,
        label: usdFoilLabel,
        price: prices.usdFoil ?? "0.00",
        sender: sender
      ),
      Model(
        action: .didSelectUSDPrice,
        isDisabled: prices.tix == nil,
        label: tixLabel,
        price: prices.tix ?? "0.00",
        sender: sender
      ),
    ]
  }
  
  private func priceButton(
    _ model: PriceView.Model,
    sender: @escaping (Action) -> Void
  ) -> some View {
    Button {
      sender(model.action)
    } label: {
      VStack(spacing: 0) {
        Text("\(model.currencySymbol)\(model.price)")
          .font(model.isDisabled ? .body : .headline)
          .monospaced()
        
        Text(model.label)
          .font(.caption)
          .tint(.secondary)
      }
      .frame(maxWidth: .infinity)
    }
    .disabled(model.isDisabled)
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
    let sender: (Action) -> Void
    
    init(
      action: Action,
      currencySymbol: String = "",
      isDisabled: Bool,
      label: String,
      price: String,
      sender: @escaping (Action) -> Void
    ) {
      self.action = action
      self.currencySymbol = currencySymbol
      self.isDisabled = isDisabled
      self.label = label
      self.price = price
      self.sender = sender
    }
    
    var body: some View {
      Button { [sender] in
        sender(action)
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
    tixLabel: "Tix"
  ) { _ in }
}
