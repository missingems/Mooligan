import SwiftUI

public struct PillText: View {
  public let label: String
  private let insets: EdgeInsets
  private let background: Color
  private let isFoil: Bool
  
  public init(
    _ label: String,
    insets: EdgeInsets = EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5),
    background: Color = Color(.systemFill),
    isFoil: Bool = false
  ) {
    self.label = label
    self.insets = insets
    self.background = background
    self.isFoil = isFoil
  }
  
  public var body: some View {
    Text(label)
      .multilineTextAlignment(.center)
      .padding(insets)
      .background {
        if isFoil {
          LinearGradient(
            colors: [Color(#colorLiteral(red: 0.9725449681, green: 0.8013705611, blue: 0.4944624901, alpha: 1)), Color(#colorLiteral(red: 0.9137322307, green: 0.9137201905, blue: 0.5514469147, alpha: 1)), Color(#colorLiteral(red: 0.5428386331, green: 0.8030003309, blue: 0.5898079276, alpha: 1)), Color(#colorLiteral(red: 0.5428386331, green: 0.8030003309, blue: 0.5898079276, alpha: 1)), Color(#colorLiteral(red: 0.6374309659, green: 0.8531000018, blue: 0.875569284, alpha: 1)), Color(#colorLiteral(red: 0.5439324379, green: 0.6502383351, blue: 0.7930879593, alpha: 1)), Color(#colorLiteral(red: 0.4611749649, green: 0.5113767385, blue: 0.7011086941, alpha: 1))],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        } else {
          background
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 8.0))
  }
}

