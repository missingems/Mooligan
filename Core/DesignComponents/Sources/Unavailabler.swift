import SwiftUI

public struct Unavailabler: ViewModifier {
  let isUnavailable: Bool
  
  public func body(content: Content) -> some View {
    content
      .disabled(isUnavailable)
      .opacity(isUnavailable ? 0.31 : 1.0)
  }
}

public extension View {
  func unavailable(_ isUnavailable: Bool) -> some View{
    modifier(Unavailabler(isUnavailable: isUnavailable))
  }
}
