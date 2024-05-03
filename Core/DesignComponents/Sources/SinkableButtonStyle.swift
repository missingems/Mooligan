import SwiftUI

public struct SinkableButtonStyle: ButtonStyle {
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? CGSize(width: 0.98, height: 0.98) : CGSize(width: 1, height: 1))
      .opacity(configuration.isPressed ? 0.3 : 1)
      .contentShape(Rectangle())
      .animation(.easeInOut(duration: configuration.isPressed ? 0.13 : 0.35), value: configuration.isPressed)
  }
}

public extension ButtonStyle where Self == SinkableButtonStyle {
  static var sinkableButtonStyle: SinkableButtonStyle {
    SinkableButtonStyle()
  }
}
