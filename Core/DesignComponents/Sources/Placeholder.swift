import SwiftUI

public struct Placeholder: ViewModifier {
  let isPlaceholder: Bool
  
  public func body(content: Content) -> some View {
    if isPlaceholder {
      content.redacted(reason: .placeholder)
    } else {
      content
    }
  }
}

public extension View {
  func placeholder(_ isPlaceholder: Bool) -> some View{
    modifier(Placeholder(isPlaceholder: isPlaceholder)).scrollDisabled(isPlaceholder)
  }
}

public struct HierarchicalToolbarButton: ButtonStyle {
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.title2)
      .symbolRenderingMode(.palette)
      .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor, DesignComponentsAsset.accentColor.swiftUIColor.quinary)
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .opacity(configuration.isPressed ? 0.31 : 1)
      .blur(radius: configuration.isPressed ? 1 : 0)
      .contentShape(Rectangle())
  }
  
  public init() {}
}
