import DesignComponents
import SwiftUI

struct TitleView: View {
  let name: String
  let manaCost: [String]
  
  var body: some View {
    HStack(alignment: .top) {
      Text(name).font(.headline)
      
      Spacer(minLength: 10.0)
      
      ManaView(
        identity: manaCost,
        size: CGSize(width: 17.0, height: 17.0),
        spacing: 2.0
      )
      .offset(
        CGSize(width: 0.0, height: 1.0)
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  init?(
    name: String?,
    manaCost: [String]
  ) {
    guard let name else { return nil }
    
    self.name = name
    self.manaCost = manaCost
  }
}

#Preview {
  VStack(alignment: .leading) {
    TitleView(
      name: "Lightning Bolt",
      manaCost: ["{R}"]
    )
  }
}
