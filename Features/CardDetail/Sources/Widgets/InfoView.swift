import DesignComponents
import SwiftUI

struct InfoView: View {
  private let widgets: [Widget]
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(widgets) { $0.view }
      }
    }
    .scrollIndicators(.hidden)
  }
  
  init(
    power: String?,
    toughness: String?,
    loyaltyCounters: String?,
    manaValue: Double?,
    collectorNumber: String?,
    colorIdentity: [String]?,
    setCode: String?,
    setIconURL: URL?
  ) {
    var widgets: [Widget] = []
    
    if let power, let toughness {
      widgets.append(.powerToughness(power: power, toughness: toughness))
    }
    
    if let loyaltyCounters {
      widgets.append(.loyalty(counters: loyaltyCounters))
    }
    
    if let manaValue {
      widgets.append(.manaValue("\(manaValue)"))
    }
    
    if let collectorNumber {
      widgets.append(.collectorNumber(collectorNumber))
    }
    
    if let colorIdentity {
      widgets.append(.colorIdentity(colorIdentity))
    }
    
    if let setCode, let setIconURL {
      widgets.append(.set(code: setCode, iconURL: setIconURL))
    }
    
    self.widgets = widgets
  }
}

@MainActor private enum Widget: Hashable, Identifiable {
  case powerToughness(power: String, toughness: String)
  case loyalty(counters: String)
  case manaValue(String)
  case collectorNumber(String)
  case colorIdentity([String])
  case set(code: String, iconURL: URL?)
  
  @ViewBuilder var view: some View {
    switch self {
    case let .powerToughness(power, toughness):
      powerToughnessView(power: power, toughness: toughness)
      
    case let .set(code, iconURL):
      setCodeView(code, iconURL: iconURL)
      
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
  @ViewBuilder func powerToughnessView(
    power: String?,
    toughness: String?
  ) -> some View {
    if let power, let toughness {
      VStack(alignment: .center) {
        content {
          Image("power", bundle: DesignComponentsResources.bundle)
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(Color.primary)
          
          Text("\(power)/\(toughness)")
            .font(.body)
            .fontDesign(.serif)
          
          Image("toughness", bundle: DesignComponentsResources.bundle)
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(Color.primary)
        }
        
        Text(String(localized: "Power\nToughness"))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        
        Spacer(minLength: 0)
      }
    }
  }
  
  @ViewBuilder private func manaIdentityView(_ identity: [String]) -> some View {
    if identity.isEmpty == false {
      VStack(alignment: .center) {
        content {
          ManaView(identity: identity, size: CGSize(width: 21, height: 21))
        }
        
        Text(String(localized: "Color\nIdentity"))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Spacer(minLength: 0)
      }
    }
  }
  
  @ViewBuilder private func loyaltyWidgetView(_ counters: String?) -> some View {
    if let counters {
      VStack(alignment: .center) {
        content {
          ZStack(alignment: .center) {
            Image("loyalty", bundle: DesignComponentsResources.bundle)
              .renderingMode(.template)
              .aspectRatio(contentMode: .fit)
              .tint(.accentColor)
            
            Text(counters)
              .foregroundStyle(Color.white)
              .font(.headline)
              .fontDesign(.serif)
          }
        }
        
        Text(String(localized: "Loyalty\nCounters"))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Spacer(minLength: 0)
      }
    }
  }
  
  @ViewBuilder private func collectionNumberView(_ collectorNumber: String?) -> some View {
    if let collectorNumber {
      VStack(alignment: .center) {
        content {
          Text("#\(collectorNumber)".uppercased()).font(.body).fontDesign(.serif)
        }
        
        Text(String(localized: "Collector\nNumber"))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Spacer(minLength: 0)
      }
    }
  }
  
  @ViewBuilder private func setCodeView(_ code: String?, iconURL: URL?) -> some View {
    if let code, let iconURL {
      VStack(alignment: .center) {
        content {
          IconLazyImage(iconURL, tintColor: .primary).frame(width: 25, height: 25)
          Text(code.uppercased()).font(.body).fontDesign(.serif)
        }
        
        Text(String(localized: "Set\nCode"))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Spacer(minLength: 0)
      }
    }
  }
  
  @ViewBuilder private func manaValueView(_ manaValue: String?) -> some View {
    if let manaValue {
      VStack(alignment: .center) {
        content {
          Text(manaValue).font(.body).fontDesign(.monospaced)
        }
        
        Text(String(localized: "Mana\nValue"))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Spacer(minLength: 0)
      }
    }
  }
}

extension Widget {
  @ViewBuilder private func content(@ViewBuilder content: () -> some View) -> some View {
    HStack(spacing: 5.0) {
      content()
    }
    .frame(minWidth: 66, minHeight: 32)
    .padding(EdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11))
    .background { Color(.systemFill) }
    .clipShape(.buttonBorder)
  }
}

#Preview {
  InfoView(
    power: "1",
    toughness: "2",
    loyaltyCounters: "1",
    manaValue: 2,
    collectorNumber: "123",
    colorIdentity: ["{R}"],
    setCode: "123",
    setIconURL: URL(string: "https://1000logos.net/wp-content/uploads/2016/10/Apple-Logo.png")
  )
}
