import SwiftUI

public struct FilterOptionRow<Icon: View>: View {
  @Environment(\.colorScheme) var colorScheme
  
  let title: String
  let isSelected: Bool
  let action: () -> Void
  let icon: () -> Icon
  
  public init(
    title: String,
    isSelected: Bool,
    action: @escaping () -> Void,
    @ViewBuilder icon: @escaping () -> Icon = { EmptyView() }
  ) {
    self.title = title
    self.isSelected = isSelected
    self.action = action
    self.icon = icon
  }
  
  public var body: some View {
    Button(action: action) {
      HStack {
        icon()
        Text(title)
        Spacer(minLength: 34)
        Image(systemName: "checkmark.circle.fill")
          .opacity(isSelected ? 1 : 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
      .background {
        Capsule()
          .fill(colorScheme == .dark ? Color.white : Color.black)
          .opacity(0.12)
          .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
          .opacity(isSelected ? 1 : 0)
      }
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .animation(.smooth, value: isSelected)
  }
}
