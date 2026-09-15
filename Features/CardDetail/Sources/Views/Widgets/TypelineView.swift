import SwiftUI

struct TypelineView: View {
  private let text: String
  
  var body: some View {
    Text(text)
      .font(.headline)
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  init?(_ text: String?) {
    guard let text else { return nil }
    self.text = text
  }
}

#Preview {
  TypelineView("Creature - Goblin")
}
