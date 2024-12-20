import DesignComponents
import Networking
import SwiftUI

struct DescriptionView: View {
  let textElements: [[TextElement]]
  let keywords: [String]
  
  init?(_ textElements: [[TextElement]], keywords: [String]) {
    guard textElements.isEmpty == false else { return nil }
    self.textElements = textElements
    self.keywords = keywords
  }
  
  var body: some View {
    TokenizedText(
      textElements: textElements,
      font: .preferredFont(forTextStyle: .body),
      paragraphSpacing: 8.0,
      keywords: keywords
    )
    .multilineTextAlignment(.leading)
    .frame(maxWidth: .infinity, alignment: .leading)
    .tint(.primary)
  }
}
