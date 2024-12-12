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
          Color.black.opacity(0.3)
          LinearGradient(
            colors: [
              Color(#colorLiteral(red: 1.0, green: 0.9, blue: 0.7, alpha: 1)),
              Color(#colorLiteral(red: 1.0, green: 1.0, blue: 0.8, alpha: 1)),
              Color(#colorLiteral(red: 0.8, green: 1.0, blue: 0.8, alpha: 1)),
              Color(#colorLiteral(red: 0.8, green: 1.0, blue: 0.8, alpha: 1)),
              Color(#colorLiteral(red: 0.85, green: 1.0, blue: 0.9, alpha: 1)),
              Color(#colorLiteral(red: 0.7, green: 0.8, blue: 1.0, alpha: 1)),
              Color(#colorLiteral(red: 0.6, green: 0.6, blue: 0.9, alpha: 1))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .blur(radius: 5)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .strokeBorder(.separator, lineWidth: 1 / UIScreen.main.nativeScale)
          )
        } else {
          background
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 8.0))
  }
}

