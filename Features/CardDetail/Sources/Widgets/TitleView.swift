import DesignComponents
import SwiftUI

public struct TitleView: View {
  let name: String
  let manaCosts: [String]
  
  public init(
    name: String,
    manaCosts: [String]
  ) {
    self.name = name
    self.manaCosts = manaCosts
  }
  
  public var body: some View {
    HStack(alignment: .top) {
      TextView(
        text: .constant(name),
        font: .preferredFont(forTextStyle: .headline),
        foregroundColor: .label
      )
      
      Spacer(minLength: 10.0)
      
      ManaView(
        identity: manaCosts,
        size: CGSize(width: 17.0, height: 17.0),
        spacing: 2.0
      )
      .offset(
        CGSize(width: 0.0, height: 1.0)
      )
    }
  }
}

#Preview {
  VStack(alignment: .leading) {
    TitleView(
      name: "Lightning Bolt",
      manaCosts: ["{R}"]
    )
  }
}
