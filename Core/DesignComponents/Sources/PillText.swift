import SwiftUI

public struct PillText: View {
  public let label: String
  private let insets: EdgeInsets
  private let background: Color
  
  public init(
    _ label: String,
    insets: EdgeInsets = EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5),
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
      .clipShape(RoundedRectangle(cornerRadius: 8.0))
  }
}

