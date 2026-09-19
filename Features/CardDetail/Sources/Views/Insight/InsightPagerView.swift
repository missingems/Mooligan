import ComposableArchitecture
import DesignComponents
import SwiftUI

/// Every tile of the information row explained, full screen over a blur of the card: a carousel of
/// their badges above, and a page for each below, swiped between.
///
/// It is presented without the cover's slide and fades itself in once it is built, and fades out
/// before it is dismissed, so it reads as an overlay rather than a new screen.
struct InsightPagerView: View {
  @Bindable var store: StoreOf<InsightPagerFeature>

  @Environment(\.dismiss) private var dismiss
  @State private var isShown = false
  /// The pages' scroll in pages, for the carousel to follow. Written here and read only by the
  /// carousel, so a swipe does not redraw this view.
  @State private var position: Double
  /// The pages' scroll, which starts on the tapped tile's page.
  @State private var scroll: ScrollPosition

  init(store: StoreOf<InsightPagerFeature>) {
    self.store = store
    _position = State(initialValue: Double(store.pages.index(id: store.opened) ?? 0))
    _scroll = State(initialValue: ScrollPosition(id: store.opened))
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        BadgeCarousel(
          widgets: store.pages.ids.elements,
          position: $position,
          opened: store.opened
        ) { widget in
          withAnimation(.smooth(duration: 0.4)) {
            scroll.scrollTo(id: widget)
          }
        }
        .equatable()

        ScrollView(.horizontal) {
          HStack(spacing: 0) {
            // By the pages' own ids, and tagged with them, as the card pager does, so the scroll can
            // be sent to a page by its tile. Without the tag no page answered to one.
            ForEach(store.pages.ids.elements, id: \.self) { id in
              if let page = store.scope(state: \.pages[id: id], action: \.pages[id: id]) {
                InsightPage(store: page)
                  .containerRelativeFrame(.horizontal)
                  .id(id)
              }
            }
          }
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition($scroll)
        .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.width } action: { width, newWidth in
          // The cover lays the pages out narrow first and at full width after, and the starting
          // page was lost between the two: they sat on the first. So whenever their width changes,
          // they are put back on the page on show.
          if let selection = store.selection {
            scroll.scrollTo(id: selection)
          }
        }
        .onScrollGeometryChange(for: Double.self) { geometry in
          geometry.contentOffset.x / max(geometry.containerSize.width, 1)
        } action: { _, newValue in
          position = newValue
        }
        // The page the pages settle on is the one on show, which starts its explanation.
        .onChange(of: scroll.viewID(type: InformationWidget.self)) { _, page in
          if let page, page != store.selection {
            store.selection = page
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .close) {
            close()
          }
          .accessibilityIdentifier("cardDetail.insight.close")
        }
      }
      .containerBackground(.clear, for: .navigation)
    }
    .background {
      Rectangle()
        .fill(.ultraThinMaterial)
        .ignoresSafeArea()
    }
    .opacity(isShown ? 1 : 0)
    .onAppear {
      withAnimation(.easeOut(duration: 0.2)) {
        isShown = true
      }
    }
    .task {
      await store.send(.appeared).finish()
    }
    .onDisappear {
      store.send(.disappeared)
    }
  }

  private func close() {
    withAnimation(.easeIn(duration: 0.2)) {
      isShown = false
    } completion: {
      var instant = Transaction()
      instant.disablesAnimations = true
      withTransaction(instant) {
        dismiss()
      }
    }
  }
}
