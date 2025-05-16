import SwiftUI

public struct ConditionalFrameModifier: ViewModifier {
  public let size: CGSize
  
  public func body(content: Content) -> some View {
    if size.width > 0, size.height > 0 {
      content.frame(width: size.width, height: size.height, alignment: .center)
    }
  }
  
  public init(size: CGSize) {
    self.size = size
  }
}

public extension View {
  @ViewBuilder
  func conditionalModifier<Content: View>(
    _ condition: Bool,
    transform: (Self) -> Content
  ) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

public extension View {
  @ViewBuilder
  func ifLet<Content: View, AnyValue>(
    _ value: AnyValue?,
    transform: (Self, AnyValue) -> Content
  ) -> some View {
    if let value {
      transform(self, value)
    } else {
      self
    }
  }
}
