import ComposableArchitecture
import DesignComponents
import Nuke
import NukeUI
import SwiftUI

public struct CardPagerCarousel: View {
  @Bindable private var store: StoreOf<CardPagerFeature>
  @State private var centeredId: UUID?
  private let width: CGFloat

  public init(store: StoreOf<CardPagerFeature>, width: CGFloat) {
    self.store = store
    self.width = width
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 0) {
          ForEach(Array(store.cards.ids), id: \.self) { id in
            if let card = store.cards[id: id], let image = card.displayableCardImage {
              let isSelected = id == store.selectedId

              LazyImage(
                request: ImageRequest(
                  url: image.showingFaceURL,
                  processors: [ImageProcessors.Resize(width: 29.0)]
                )
              ) { state in
                Color.primary.opacity(0.116).overlay {
                  if let image = state.image {
                    image.resizable()
                  }
                }
              }
              .frame(width: 29.0, height: 40.0)
              .clipShape(RoundedRectangle(cornerRadius: 3.0, style: .continuous))
              .overlay {
                RoundedRectangle(cornerRadius: 3.0, style: .continuous)
                  .strokeBorder(DesignComponentsAsset.accentColor.swiftUIColor, lineWidth: 2.0)
                  .opacity(isSelected ? 1 : 0)
              }
              .opacity(isSelected ? 1 : 0.5)
              .scaleEffect(isSelected ? 1.1 : 1)
              .animation(.smooth, value: isSelected)
              .frame(width: 32.0, height: 44.0)
              .contentShape(.rect)
              .onTapGesture {
                store.selectedId = id
              }
              .accessibilityIdentifier("cardDetail.carousel.\(card.content.card.collectorNumber)")
              .id(id)
            }
          }
        }
        .scrollTargetLayout()
      }
      .contentMargins(.horizontal, max(0, (width - 32.0) / 2), for: .scrollContent)
      .scrollTargetBehavior(.viewAligned(anchor: .center))
      .scrollPosition(id: $centeredId, anchor: .center)
      .onScrollPhaseChange { oldPhase, newPhase in
        if newPhase == .idle, oldPhase == .decelerating || oldPhase == .interacting,
           let centeredId, centeredId != store.selectedId {
          store.selectedId = centeredId
        }
      }
      .frame(width: width, height: 44.0)
      .clipShape(.capsule)
      .glassEffect(.regular, in: .capsule)
      .task(id: width) {
        proxy.scrollTo(store.selectedId, anchor: .center)
      }
      .onChange(of: store.selectedId) { _, newValue in
        withAnimation(.smooth) {
          proxy.scrollTo(newValue, anchor: .center)
        }
      }
      .accessibilityIdentifier("cardDetail.carousel")
    }
  }
}
