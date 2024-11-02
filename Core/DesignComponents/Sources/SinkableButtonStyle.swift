import SwiftUI

public struct SinkableButtonStyle: ButtonStyle {
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .opacity(configuration.isPressed ? 0.3 : 1)
      .contentShape(Rectangle())
      .animation(.interactiveSpring, value: configuration.isPressed)
  }
}

public extension ButtonStyle where Self == SinkableButtonStyle {
  static var sinkableButtonStyle: SinkableButtonStyle {
    SinkableButtonStyle()
  }
}
