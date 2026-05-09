import SwiftUI

public struct VibrantDivider: View {
  @Environment(\.colorScheme) private var colorScheme
  
  public var body: some View {
    Divider()
      .opacity(0)
      .overlay(
        Rectangle()
          .fill(colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225))
          .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
      )
  }
  
  public init() {}
}

public struct VibrantVerticalDivider: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) var displayScale
  
  public var body: some View {
    Rectangle()
      .fill(colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225))
      .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
      .frame(width: 1 / displayScale)
  }
  
  public init() {}
}
