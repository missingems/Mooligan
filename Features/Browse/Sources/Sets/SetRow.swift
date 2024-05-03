import DesignComponents
import SwiftUI

struct SetRow: View {
  let viewModel: ViewModel
  
  var body: some View {
    HStack(spacing: 11.0) {
      if viewModel.shouldShowIndentIndicator {
        childIndicatorImage.frame(width: 30, height: 30)
      }
      
      iconImage.frame(width: 30, height: 30, alignment: .center)
      
      VStack(alignment: .leading, spacing: 3.0) {
        titleLabel
        
        HStack(spacing: 5.0) {
          setCodeLabel
          numberOfCardsLabel
        }
      }
      
      Spacer()
      disclosureIndicator
    }
    .padding(insets)
    .background { backgroundColor }
    .clipShape(.buttonBorder)
  }
}

// MARK: - Configuration

extension SetRow {
  private var insets: EdgeInsets {
    EdgeInsets(
      top: viewModel.shouldSetBackground ? 8 : 11,
      leading: 13,
      bottom: viewModel.shouldSetBackground ? 11 : 13,
      trailing: 13
    )
  }
  
  private var backgroundColor: Color {
    if viewModel.isHighlighted {
      if viewModel.colorScheme == .dark {
        return Color.accentColor.opacity(0.382)
      } else {
        return Color.accentColor
      }
    } else {
      return viewModel.shouldSetBackground ? Color(.tertiarySystemFill) : Color.clear
    }
  }
  
  private var foregroundColor: Color {
    if viewModel.isHighlighted {
      if viewModel.colorScheme == .dark {
        return Color.accentColor
      } else {
        return Color.white
      }
    } else {
      return Color.primary
    }
  }
  
  private var tintColor: Color {
    if viewModel.isHighlighted {
      if viewModel.colorScheme == .dark {
        return DesignComponentsAsset.accentColor.swiftUIColor
      } else {
        return Color.white
      }
    } else {
      return DesignComponentsAsset.accentColor.swiftUIColor
    }
  }
  
  private var tertiaryColor: Color {
    if viewModel.isHighlighted {
      if viewModel.colorScheme == .dark {
        return DesignComponentsAsset.accentColor.swiftUIColor
      } else {
        return Color.white.opacity(0.618)
      }
    } else {
      return Color(.tertiaryLabel)
    }
  }
  
  private var secondaryColor: Color {
    if viewModel.isHighlighted {
      if viewModel.colorScheme == .dark {
        return DesignComponentsAsset.accentColor.swiftUIColor
      } else {
        return Color.white.opacity(0.618)
      }
    } else {
      return Color.secondary
    }
  }
}

// MARK: - UI Properties

extension SetRow {
  private var childIndicatorImage: some View {
    Image(systemName: viewModel.childIndicatorImageName)
      .foregroundColor(tertiaryColor)
      .fontWeight(.medium)
      .imageScale(.small)
  }
  
  private var iconImage: some View {
    IconLazyImage(viewModel.iconUrl, tintColor: tintColor)
  }
  
  private var titleLabel: some View {
    Text(viewModel.title).multilineTextAlignment(.leading).foregroundColor(foregroundColor)
  }
  
  private var setCodeLabel: some View {
    PillText(viewModel.id).font(.caption).monospaced().foregroundColor(foregroundColor)
  }
  
  private var numberOfCardsLabel: some View {
    Text(viewModel.numberOfCardsLabel).font(.caption).foregroundColor(secondaryColor)
  }
  
  private var disclosureIndicator: some View {
    Image(systemName: viewModel.disclosureIndicatorImageName)
      .foregroundColor(tertiaryColor)
      .fontWeight(.medium)
      .imageScale(.small)
  }
}

extension SetRow {
  struct ViewModel: Equatable {
    let childIndicatorImageName: String
    let disclosureIndicatorImageName: String
    let iconUrl: URL?
    let id: String
    var colorScheme: ColorScheme
    var isHighlighted: Bool
    let shouldShowIndentIndicator: Bool
    let numberOfCardsLabel: String
    let shouldSetBackground: Bool
    let title: String
    
    init(
      iconURL: URL?,
      id: String,
      colorScheme: ColorScheme,
      isHighlighted: Bool,
      index: Int,
      numberOfCards: Int,
      shouldShowIndentIndicator: Bool,
      title: String
    ) {
      childIndicatorImageName = "arrow.turn.down.right"
      disclosureIndicatorImageName = "chevron.right"
      iconUrl = iconURL
      self.id = id.uppercased()
      self.colorScheme = colorScheme
      self.isHighlighted = isHighlighted
      self.shouldShowIndentIndicator = shouldShowIndentIndicator
      numberOfCardsLabel = String(localized: "\(numberOfCards) Cards")
      shouldSetBackground = index.isMultiple(of: 2)
      self.title = title
    }
  }
}
