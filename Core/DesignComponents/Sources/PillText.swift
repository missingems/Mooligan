import SwiftUI

public struct PillText: View {
  public let label: String
  private let insets: EdgeInsets
  private let background: Color
  
  public init(
    _ label: String,
    insets: EdgeInsets = EdgeInsets(top: 1, leading: 3, bottom: 1, trailing: 3),
    background: Color = Color(.systemFill)
  ) {
    self.label = label
    self.insets = insets
    self.background = background
  }
  
  public var body: some View {
    Text(label)
      .multilineTextAlignment(.center)
      .padding(insets)
      .background { background }
      .clipShape(.buttonBorder)
  }
}

