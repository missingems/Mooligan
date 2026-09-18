import SwiftUI

/// The surface a card draws when it wants none. `CardView` compares its surface, and SwiftUI's own
/// `EmptyModifier` is not `Equatable`.
public struct EmptyCardSurface: ViewModifier, Equatable {
  public init() {}

  public func body(content: Content) -> some View {
    content
  }
}
