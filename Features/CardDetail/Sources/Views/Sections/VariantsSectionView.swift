import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct VariantsSectionView: View {
  let store: StoreOf<CardDetailFeature>
  
  var body: some View {
    let variants = store.variants
    
    if let cards = variants.state.value {
      HorizontalCardScrollView(
        title: variants.title,
        subtitle: variants.subtitle,
        cards: cards,
        isInitial: variants.state.isInitial
      ) { [store] action in
        switch action {
        case let .didSelectCard(card):
          store.send(.didSelectVariant(card: card, queryType: store.content.queryType))
          
        case let .didShowCardAtIndex(index):
          store.send(.didShowVariant(index: index))
        }
      }
    }
  }
}
