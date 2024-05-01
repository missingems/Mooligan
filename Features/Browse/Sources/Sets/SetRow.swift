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
    .padding(margins)
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
  
  private var margins: EdgeInsets {
    EdgeInsets(
      top: 0,
      leading: 11,
      bottom: 0,
      trailing: 11
    )
  }
  
  private var backgroundColor: Color {
    if viewModel.isHighlighted {
      if viewModel.isDarkMode {
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
      if viewModel.isDarkMode {
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
      if viewModel.isDarkMode {
        return Color.accentColor
      } else {
        return Color.white
      }
    } else {
      return Color.accentColor
    }
  }
  
  private var tertiaryColor: Color {
    if viewModel.isHighlighted {
      if viewModel.isDarkMode {
        return Color.accentColor
      } else {
        return Color.white.opacity(0.618)
      }
    } else {
      return Color(.tertiaryLabel)
    }
  }
  
  private var secondaryColor: Color {
    if viewModel.isHighlighted {
      if viewModel.isDarkMode {
        return Color.accentColor
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
    Text("icon")
  }
  
  private var titleLabel: some View {
    Text(viewModel.title).multilineTextAlignment(.leading).foregroundColor(foregroundColor)
  }
  
  private var setCodeLabel: some View {
    Text(viewModel.id).font(.caption).monospaced().foregroundColor(foregroundColor)
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
    var isDarkMode: Bool
    var isHighlighted: Bool
    let shouldShowIndentIndicator: Bool
    let numberOfCardsLabel: String
    let shouldSetBackground: Bool
    let title: String
    
    init(
      iconURL: URL?,
      id: String,
      isDarkMode: Bool,
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
      self.isDarkMode = isDarkMode
      self.isHighlighted = isHighlighted
      self.shouldShowIndentIndicator = shouldShowIndentIndicator
      numberOfCardsLabel = String(localized: "\(numberOfCards) Cards")
      shouldSetBackground = index.isMultiple(of: 2)
      self.title = title
    }
  }
}
