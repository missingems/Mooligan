import DesignComponents
import Networking
import SwiftUI

struct RelatedCardsSectionView: View {
  let section: Content.SubContent?
  
  var body: some View {
    if let section, let cards = section.state.value {
      HorizontalCardScrollView(
        title: section.title,
        subtitle: section.subtitle,
        cards: cards,
        isInitial: section.state.isInitial
      ) { _ in }
    }
  }
}
