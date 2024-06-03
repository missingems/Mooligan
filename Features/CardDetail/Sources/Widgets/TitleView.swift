import DesignComponents
import SwiftUI

struct TitleView: View {
  let name: String
  let manaCosts: [String]
  
  var body: some View {
    HStack(alignment: .top) {
      Text(name)
        .font(.headline)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
      
      Spacer()
      
      ManaView(
        identity: manaCosts,
        size: CGSize(width: 17, height: 17),
        spacing: 2.0
      )
      .frame(maxWidth: 120)
      .offset(CGSize(width: 0, height: 1))
    }
    .padding(.horizontal, 16.0)
  }
}

#Preview {
  TitleView(
    name: "A very very long Eidolon",
    manaCosts: ["{B}", "{C}", "{2}", "{R}", "{U}", "{1}", "{W}", "{R}", "{INFINITY}", "{0}", "{100}", "{R}"]
  )
}
