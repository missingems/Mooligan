import ComposableArchitecture
import DesignComponents
import Networking
import Nuke
import NukeUI
import SwiftUI

public struct CardDetailView: View {
  @Bindable var store: StoreOf<CardDetailFeature>
  @State private var maxWidth: CGFloat = .initialScreenWidth
  @Environment(\.displayScale) private var displayScale
  
  public init(store: StoreOf<CardDetailFeature>) {
    self.store = store
  }
  
  public var body: some View {
    let content = store.content
    let faceDirection = store.displayableCardImage?.faceDirection
    
    ScrollView(.vertical) {
      // Sections keep to the margin with `padding`. A `safeAreaPadding` measures its content three
      // times over for every size it is asked, and with one on each section that was most of the
      // cost of the pager building a page. Only the rows that scroll sideways keep the safe-area
      // inset, so their cards run under the margin.
      VStack(spacing: 0) {
        let cardImageWidth = content.card.isLandscape
        ? 2.5 / 3.0 * maxWidth
        : 2.0 / 3.0 * maxWidth
        
        let configuration = CardView.LayoutConfiguration(
          rotation: content.card.isLandscape ? .landscape : .portrait,
          maxWidth: cardImageWidth.rounded()
        )
        
        CardView(
          displayableCard: store.displayableCardImage,
          layoutConfiguration: configuration,
          callToActionHorizontalOffset: 21.0,
          priceVisibility: .hidden,
          shadowConfiguration: .default
        ) { action in
          store.send(.descriptionCallToActionTapped, animation: .bouncy)
        }
        .padding(
          EdgeInsets(top: 13, leading: 55, bottom: 34, trailing: 55)
        )
        // Exactly the page's width, so a landscape card and its padding (wider than the page on
        // a phone) can't widen the stack and, through `maxWidth`, grow the card again.
        .frame(width: maxWidth)
        .zIndex(1)
        
        // Read-only sections ignore touches, so the hit tests that run on every touch (including
        // the one that starts a pager swipe) skip their text.
        CardDetailTableView(descriptions: content.getDescriptions(faceDirection: faceDirection))
          .allowsHitTesting(false)
        
        InformationSectionView(
          store: store,
          content: content,
          faceDirection: faceDirection
        )
        
        if let label = content.card.layout.callToActionLabel,
           let icon = content.card.layout.callToActionIconName {
          Button {
            store.send(.descriptionCallToActionTapped, animation: .bouncy)
          } label: {
            Label {
              Text(label)
                .font(.body)
                .fontWeight(.semibold)
            } icon: {
              Image(systemName: icon)
                .fontWeight(.semibold)
            }
            .foregroundStyle(DesignComponentsAsset.invertedPrimary.swiftUIColor)
            .frame(maxWidth: .infinity, minHeight: 34)
            .padding(.vertical, 5.0)
            .background(DesignComponentsAsset.accentColor.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
              RoundedRectangle(cornerRadius: 13)
                .strokeBorder(.separator, lineWidth: 1 / displayScale)
            )
          }
          .buttonStyle(.sinkableButtonStyle)
          .padding(.horizontal, systemHorizontalMargin)
        }
        
        if content.card.isTransformable || content.card.isFlippable {
          Spacer(minLength: 13.0)
        }
        
        LegalityView(
          title: content.legalityLabel,
          displayReleaseDate: content.card.releasedAt,
          legalities: content.card.legalities.all
        )
        .allowsHitTesting(false)
        
        PriceHistorySectionView(store: store, labels: content.priceHistoryLabels)
        
        VariantsSectionView(store: store)
        RelatedTokensSectionView(store: store)
        RelatedComboPiecesSectionView(store: store)
        RelatedMeldPiecesSectionView(store: store)
        RelatedMeldResultSectionView(store: store)
        
        SelectionView(
          items: [
            SelectionView.Item(
              icon: content.artistSelectionIcon,
              title: content.artistSelectionLabel,
              detail: content.card.artist
            ) {},
            SelectionView.Item(
              icon: content.rulingSelectionIcon,
              title: content.rulingSelectionLabel
            ) {
              store.send(.viewRulingsTapped)
            },
          ]
        )
      }
    }
    // Measures the page, not its content: the card is sized from `maxWidth`, so measuring the
    // content fed a landscape card's overflow back into its own size.
    .onGeometryChange(for: CGFloat.self, of: { proxy in
      proxy.size.width
    }, action: { newValue in
      if abs(maxWidth - newValue) > 5.0 {
        maxWidth = newValue
      }
    })
    .scrollEdgeEffectStyle(.soft, for: .all)
    .accessibilityIdentifier("cardDetail.scroll")
    .task(priority: .background) {
      // The page loads the moment the pager shows it. SwiftUI starts this task inside the update
      // that first shows the page, and a send has no suspension point, so without the yield the
      // send and its state changes land in that frame.
      await Task.yield()
      guard Task.isCancelled == false else { return }
      await store.send(.viewAppeared).finish()
    }
    .background {
      ZStack {
        // Only the face on show gets a backdrop. Flipping swaps it with a crossfade, instead of
        // keeping both faces' images loaded and blurred with one of them at zero opacity.
        if let faceDirection {
          let url = content.card.getImageURL(type: .normal, getSecondFace: faceDirection == .back)
          backdrop(for: url)
            .id(faceDirection.id)
            .transition(.opacity)
        }

        Color(asset: DesignComponentsAsset.backgroundPlaceholder)
      }
      .allowsHitTesting(false)
      .ignoresSafeArea()
    }
  }
  
  private func backdrop(for url: URL?) -> some View {
    LazyImage(
      request: ImageRequest(url: url, processors: [ArtCropImageProcessor()]),
      transaction: Transaction(animation: .smooth)
    ) { state in
      if let image = state.image {
        image
          .resizable()
          .blur(radius: 89, opaque: true)
      }
    }
  }
}
