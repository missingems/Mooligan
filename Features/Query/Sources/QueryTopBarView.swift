import DesignComponents
import SwiftUI
import ComposableArchitecture

struct QueryTopBarView: View {
  @Bindable var store: StoreOf<QueryFeature>
  let searchMorph: Namespace.ID
  let availableWidth: CGFloat?
  
  var body: some View {
    if store.mode.shouldHideTopBar == false {
      GlassEffectContainer {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8.0) {
            if !store.isSearchExpanded {
              ColorTypeItemsView(store: store)
              CardTypeItemsView(store: store)
              SortOptionsView(store: store)
            }
            
            SearchBar(
              text: $store.query.name,
              isExpanded: $store.isSearchExpanded,
              isLoading: store.mode.isLoading,
              placeholder: store.searchPrompt
            )
            .glassEffectID("searchBar", in: searchMorph)
          }
          .frame(minWidth: availableWidth)
        }
      }
      .animation(.default, value: store.isSearchExpanded)
      .animation(.default, value: store.query)
    }
  }
}
