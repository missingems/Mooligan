import Networking
import SwiftUI

struct PriceView: View {
  enum Action: Sendable, Equatable {
    case didSelectPrice
  }
    
  private let title: String
  private let subtitle: String
  private let prices: any MagicCardPrices
  private let usdLabel: String
  private let usdFoilLabel: String
  private let tixLabel: String
  private let send: (Action) -> Void
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.headline)
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
      
      HStack(alignment: .center, spacing: 5.0) {
        Button {
          print("Implement View Rulings")
        } label: {
          VStack(spacing: 0) {
            Text("$\(prices.usd ?? "0.00")")
              .font(prices.usd == nil ? .body : .headline)
              .monospaced()
            Text(usdLabel).font(.caption).tint(.secondary)
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(prices.usd == nil)
        
        Button {
          print("Implement View Rulings")
        } label: {
          VStack(spacing: 0) {
            Text("$\(prices.usdFoil ?? "0.00")")
              .font(prices.usdFoil == nil ? .body : .headline)
              .monospaced()
            Text(usdFoilLabel).font(.caption).tint(.secondary)
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(prices.usdFoil == nil)
        
        Button {
          print("Implement View Rulings")
        } label: {
          VStack(spacing: 0) {
            Text("\(prices.tix ?? "0.00")")
              .font(prices.tix == nil ? .body : .headline)
              .monospaced()
            Text(tixLabel).font(.caption).tint(.secondary)
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(prices.tix == nil)
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
    send: @escaping (Action) -> Void
  ) {
    self.title = title
    self.subtitle = subtitle
    self.prices = prices
    self.usdLabel = usdLabel
    self.usdFoilLabel = usdFoilLabel
    self.tixLabel = tixLabel
    self.send = send
  }
}

#Preview {
  PriceView(
    title: "Market PRices",
    subtitle: "Data from Scryfall",
    prices: MagicCardFixtures.split.value.getPrices(),
    usdLabel: "USD",
    usdFoilLabel: "USD - Foil",
    tixLabel: "Tix"
  ) { _ in }
}
