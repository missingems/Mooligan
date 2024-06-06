import DesignComponents
import SwiftUI

struct TitleView: View {
  let name: String
  let manaCosts: [String]
  
  var body: some View {
    HStack(alignment: .top) {
      Text(name).font(.headline)
      
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
  
  init?(
    name: String?,
    manaCosts: [String]
  ) {
    guard let name else { return nil }
    
    self.name = name
    self.manaCosts = manaCosts
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
