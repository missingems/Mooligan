import SwiftUI

public struct SinkableButtonStyle: ButtonStyle {
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .opacity(configuration.isPressed ? 0.31 : 1)
      .blur(radius: configuration.isPressed ? 1 : 0)
      .contentShape(Rectangle())
      .animation(.easeInOut(duration: configuration.isPressed ? 0.12 : 0.32), value: configuration.isPressed)
  }
}

public struct BorderedSinkableButtonStyle: ButtonStyle {
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5))
      .background {
        RoundedRectangle(cornerRadius: 8.0).fill(Color(.systemFill))
      }
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .opacity(configuration.isPressed ? 0.31 : 1)
      .blur(radius: configuration.isPressed ? 1 : 0)
      .contentShape(Rectangle())
      .animation(.easeInOut(duration: configuration.isPressed ? 0.12 : 0.32), value: configuration.isPressed)
      .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
  }
}

public extension ButtonStyle where Self == SinkableButtonStyle {
  static var sinkableButtonStyle: SinkableButtonStyle {
    SinkableButtonStyle()
  }
}

public extension ButtonStyle where Self == BorderedSinkableButtonStyle {
  static var borderSinkableButtonStyle: BorderedSinkableButtonStyle {
    BorderedSinkableButtonStyle()
  }
}
