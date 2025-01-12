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
