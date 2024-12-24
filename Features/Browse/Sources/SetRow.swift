import DesignComponents
import SwiftUI

struct SetRow: View {
  private let viewModel: ViewModel
  private var onSelect: () -> ()
  
  var body: some View {
    Button(
      action: {
        onSelect()
      },
      label: {
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
        .clipShape(RoundedRectangle(cornerRadius: 13.0))
      }
    )
    .buttonStyle(.sinkableButtonStyle)
  }
  
  init(viewModel: ViewModel, _ onSelect: @escaping () -> Void) {
    self.viewModel = viewModel
    self.onSelect = onSelect
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
    if viewModel.isSelected {
      if viewModel.colorScheme == .dark {
        return DesignComponentsAsset.accentColor.swiftUIColor.opacity(0.382)
      } else {
        return DesignComponentsAsset.accentColor.swiftUIColor
      }
    } else {
      return viewModel.shouldSetBackground ? Color(.tertiarySystemFill) : Color.clear
    }
  }
  
  private var foregroundColor: Color {
    if viewModel.isSelected {
      if viewModel.colorScheme == .dark {
        return DesignComponentsAsset.accentColor.swiftUIColor
      } else {
        return Color.white
      }
    } else {
      return Color.primary
    }
  }
  
  private var tintColor: Color {
    if viewModel.isSelected {
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
    if viewModel.isSelected {
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
    if viewModel.isSelected {
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
    IconLazyImage(viewModel.iconUrl)
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
