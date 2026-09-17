import SwiftUI

struct FlavorView: View {
  let flavorText: String
  
  var body: some View {
    Text(flavorText)
      .font(.body)
      .fontDesign(.serif)
      .italic()
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  init?(_ flavorText: String?) {
    guard let flavorText else { return nil }
    self.flavorText = flavorText
  }
}

#Preview {
  FlavorView("The shackles of reality were stifling. It would unmake all that had bound it.")
}
