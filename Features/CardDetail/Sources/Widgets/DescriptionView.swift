import DesignComponents
import Networking
import SwiftUI

struct DescriptionView: View {
  let textElements: [[TextElement]]
  
  init?(_ textElements: [[TextElement]]) {
    guard textElements.isEmpty == false else { return nil }
    self.textElements = textElements
  }
  
  var body: some View {
    TokenizedText(
      textElements: textElements,
      font: .preferredFont(forTextStyle: .body),
      paragraphSpacing: 8.0
    )
    .multilineTextAlignment(.leading)
    .tint(.primary)
  }
}
