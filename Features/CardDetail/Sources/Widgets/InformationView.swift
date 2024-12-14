import DesignComponents
import Networking
import SwiftUI

struct InformationView: View {
  private let title: String
  private let widgets: [Widget]
  
  var body: some View {
    Divider().safeAreaPadding(.leading, nil)
    
    VStack(alignment: .leading, spacing: 8.0) {
      Text(title).font(.headline)
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 5.0) {
          ForEach(widgets) { $0 }
        }
      }
      .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }
    .safeAreaPadding(.horizontal, nil)
    .padding(.vertical, 13.0)
  }
  
  init(
    title: String,
    power: String?,
    toughness: String?,
    loyaltyCounters: String?,
    manaValue: Double?,
    rarity: MagicCardRarityValue,
    collectorNumber: String?,
    colorIdentity: [String]?,
    setCode: String?,
    setIconURL: URL?
  ) {
    self.title = title
    
    var widgets: [Widget] = []
    
    if let setCode {
      widgets.append(.set(code: setCode, rarity: rarity, iconURL: setIconURL))
    }
    
    if let collectorNumber {
      widgets.append(.collectorNumber(collectorNumber))
    }
    
    if let colorIdentity {
      widgets.append(.colorIdentity(colorIdentity))
    }
    
    if let manaValue {
      widgets.append(.manaValue("\(manaValue)"))
    }
    
    if let loyaltyCounters {
      widgets.append(.loyalty(counters: loyaltyCounters))
    }
    
    if let power, let toughness {
      widgets.append(.powerToughness(power: power, toughness: toughness))
    }
    
    self.widgets = widgets
  }
}

private enum Widget: Hashable, Identifiable, View {
  case powerToughness(power: String, toughness: String)
  case loyalty(counters: String)
  case manaValue(String)
  case collectorNumber(String)
  case colorIdentity([String])
  case set(code: String, rarity: MagicCardRarityValue, iconURL: URL?)
  
  var body: some View {
    switch self {
    case let .powerToughness(power, toughness):
      powerToughnessView(power: power, toughness: toughness)
      
    case let .set(code, rarity, iconURL):
      setCodeView(code, rarity: rarity, iconURL: iconURL)
      
    case let .colorIdentity(manaIdentity):
      manaIdentityView(manaIdentity)
      
    case let .collectorNumber(number):
      collectionNumberView(number)
      
    case let .loyalty(counters):
      loyaltyWidgetView(counters)
      
    case let .manaValue(value):
      manaValueView(value)
    }
  }
  
  nonisolated(unsafe) var id: Self {
    return self
  }
}

private extension Widget {
  @ViewBuilder private func powerToughnessView(
    power: String?,
    toughness: String?
  ) -> some View {
    if let power, let toughness {
      VStack(alignment: .center, spacing: 3) {
        Self.wrappedContent {
          Image("power", bundle: DesignComponentsResources.bundle)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 15)
            .foregroundStyle(.primary)
          
          Text("\(power)/\(toughness)")
            .font(.body)
            .fontDesign(.serif)
          
          Image("toughness", bundle: DesignComponentsResources.bundle)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 15)
            .foregroundStyle(.primary)
        }
        
        Text(String(localized: "Power\nToughness"))
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxHeight: .infinity, alignment: .center)
      }
    }
  }
  
  @ViewBuilder private func manaIdentityView(_ identity: [String]) -> some View {
    if identity.isEmpty == false {
      VStack(alignment: .center, spacing: 3.0) {
        Self.wrappedContent {
          ManaView(identity: identity, size: CGSize(width: 21, height: 21))?.offset(y: -1)
        }
        
        Text(String(localized: "Color\nIdentity"))
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxHeight: .infinity, alignment: .center)
      }
    }
  }
  
  @ViewBuilder private func loyaltyWidgetView(_ counters: String?) -> some View {
    if let counters {
      VStack(alignment: .center, spacing: 3.0) {
        Self.wrappedContent {
          ZStack(alignment: .center) {
            Image("loyalty", bundle: DesignComponentsResources.bundle)
              .resizable()
              .renderingMode(.template)
              .aspectRatio(contentMode: .fit)
              .frame(width: 50)
              .tint(.accentColor)
            
            Text(counters)
              .font(.body)
              .fontWeight(.medium)
              .fontDesign(.serif)
              .offset(y: 1)
              .colorInvert()
          }
        }
        
        Text(String(localized: "Loyalty\nCounters"))
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxHeight: .infinity, alignment: .center)
      }
    }
  }
  
  @ViewBuilder private func collectionNumberView(_ collectorNumber: String?) -> some View {
    if let collectorNumber {
      VStack(alignment: .center, spacing: 3.0) {
        Self.wrappedContent {
          Text("#\(collectorNumber)".uppercased()).font(.body).fontDesign(.serif)
        }
        
        Text(String(localized: "Collector\nNumber"))
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxHeight: .infinity, alignment: .center)
      }
    }
  }
  
  @ViewBuilder private func setCodeView(
    _ code: String?,
    rarity: MagicCardRarityValue,
    iconURL: URL?
  ) -> some View {
    let colors = rarity.colorNames?.map({ Color($0, bundle: DesignComponentsResources.bundle)})
    
    if let code {
      VStack(alignment: .center, spacing: 3.0) {
        HStack(spacing: 5.0) {
          IconLazyImage(iconURL, tintColor: .primary).frame(width: 25, height: 25)
          Text(code.uppercased()).font(.body).fontDesign(.serif)
        }
        .frame(minWidth: 66, minHeight: 34)
        .padding(EdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11))
        .background {
          if let colors {
            LinearGradient(
              colors: colors,
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
            .overlay(
              RoundedRectangle(cornerRadius: 13.0).strokeBorder(.black.opacity(0.31), lineWidth: 1 / UIScreen.main.nativeScale)
            )
          } else {
            Color(.systemFill)
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 13.0))
        
        Text("\(rarity.rawValue.capitalized)\n ")
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxHeight: .infinity, alignment: .center)
      }
    }
  }
  
  @ViewBuilder private func manaValueView(_ manaValue: String?) -> some View {
    if let manaValue {
      VStack(alignment: .center, spacing: 3.0) {
        Self.wrappedContent {
          Text(manaValue)
            .font(.body)
            .fontDesign(.monospaced)
        }
        
        Text(String(localized: "Mana\nValue"))
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxHeight: .infinity, alignment: .center)
      }
    }
  }
}

extension Widget {
  @ViewBuilder private static func wrappedContent(@ViewBuilder content: () -> some View) -> some View {
    HStack(spacing: 5.0) {
      content()
    }
    .frame(minWidth: 66, minHeight: 34)
    .padding(EdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11))
    .background(Color(.systemFill))
    .clipShape(RoundedRectangle(cornerRadius: 13.0))
  }
}
