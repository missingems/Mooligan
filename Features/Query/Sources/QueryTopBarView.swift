import ComposableArchitecture
import DesignComponents
import SwiftUI

struct QueryTopBarView: View {
  @Bindable var store: StoreOf<QueryFeature>

  var body: some View {
    if store.mode.shouldHideTopBar == false {
      GlassEffectContainer {
        // A plain row rather than a horizontal scroll view: the grid's scroll modifiers are applied
        // outside the bar, so a scroll view up here took the grid's margins and position as well.
        // The spacing is the grid's own content margin, which the scroll view used to pick up.
        HStack(spacing: 8.0) {
          ColorTypeItemsView(store: store)
          CardTypeItemsView(store: store)
          SortOptionsView(store: store)
        }
        .padding(.horizontal, systemHorizontalMargin)
        .padding(.bottom, 13.0)
      }
      .animation(.default, value: store.query)
    }
  }
}
