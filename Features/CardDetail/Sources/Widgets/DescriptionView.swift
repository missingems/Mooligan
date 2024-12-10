import DesignComponents
import SwiftUI

struct DescriptionView: View {
  let text: String
  let keywords: [String]
  
  init?(_ text: String?, keywords: [String]) {
    guard let text else { return nil }
    self.text = text
    self.keywords = keywords
  }
  
  var body: some View {
    TokenizedText(
      text: text,
      font: .preferredFont(forTextStyle: .body),
      paragraphSpacing: 8.0,
      keywords: keywords
    )
    .multilineTextAlignment(.leading)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  DescriptionView("Crazy 8 - {R}", keywords: ["Crazy"])
}
