import DesignComponents
import SwiftUI

struct DescriptionView: View {
  let text: String
  
  init(_ text: String) {
    self.text = text
  }
  
  var body: some View {
    TokenizedText(
      text: text,
      font: .preferredFont(forTextStyle: .body),
      paragraphSpacing: 8.0
    )
    .multilineTextAlignment(.leading)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  DescriptionView("Crazy 8 - {R}")
}

