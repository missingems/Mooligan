import SwiftUI

public struct FilterOptionRow<Icon: View>: View {
  @Environment(\.colorScheme) var colorScheme
  
  let title: String
  let isSelected: Bool
  let isPreviousSelected: Bool
  let isNextSelected: Bool
  let action: () -> Void
  let icon: () -> Icon
  
  public init(
    title: String,
    isSelected: Bool,
    isPreviousSelected: Bool = false,
    isNextSelected: Bool = false,
    action: @escaping () -> Void,
    @ViewBuilder icon: @escaping () -> Icon = { EmptyView() }
  ) {
    self.title = title
    self.isSelected = isSelected
    self.isPreviousSelected = isPreviousSelected
    self.isNextSelected = isNextSelected
    self.action = action
    self.icon = icon
  }
  
  private var topRadius: CGFloat {
    isPreviousSelected ? 8 : 21
  }
  
  private var bottomRadius: CGFloat {
    isNextSelected ? 8 : 21
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
        UnevenRoundedRectangle(
          topLeadingRadius: topRadius,
          bottomLeadingRadius: bottomRadius,
          bottomTrailingRadius: bottomRadius,
          topTrailingRadius: topRadius,
          style: .continuous
        )
        .fill(.black)
        .opacity(colorScheme == .dark ? 0.32 : 0.12)
        .opacity(isSelected ? 1 : 0)
      }
      .contentShape(.rect)
    }
    .buttonStyle(.sinkableButtonStyle)
    .animation(.smooth, value: isSelected)
    .animation(.smooth, value: isPreviousSelected)
    .animation(.smooth, value: isNextSelected)
  }
}
