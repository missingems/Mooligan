import ComposableArchitecture
import DesignComponents
import Networking
import Nuke
import NukeUI
import SwiftUI

public struct CardDetailView: View {
  @Bindable var store: StoreOf<CardDetailFeature>
  private let scrub: CarouselScrub?
  @State private var maxWidth: CGFloat = .initialScreenWidth
  @State private var scrollPosition = ScrollPosition(edge: .top)
  @State private var showsSections: Bool
  @State private var isAtTop = true
  @State private var surfaceIntensity: Double = 1
  @Environment(\.displayScale) private var displayScale
  
  public init(store: StoreOf<CardDetailFeature>, scrub: CarouselScrub? = nil) {
    self.store = store
    self.scrub = scrub
    _showsSections = State(initialValue: scrub?.isSettledUntracked != false)
  }
  
  public var body: some View {
    let content = store.content
    let faceDirection = store.displayableCardImage?.faceDirection
    // Read from the landing itself rather than seeded at `init`, because the pager builds the
    // neighbouring pages before a scrub ever starts, and those were born with the effect already on.
    let isSurfaceHidden = scrub?.hidesLanding(of: store.id) == true
    
    ScrollView(.vertical) {
      // Sections keep to the margin with `padding`. A `safeAreaPadding` measures its content three
      // times over for every size it is asked, and with one on each section that was most of the
      // cost of the pager building a page. Only the rows that scroll sideways keep the safe-area
      // inset, so their cards run under the margin.
      VStack(spacing: 0) {
        let configuration = CardLayoutConfiguration.detailPage(
          isLandscape: content.card.isLandscape,
          pageWidth: maxWidth
        )
        
        CardView(
          displayableCard: store.displayableCardImage,
          layoutConfiguration: configuration,
          surface: CardSurface(isFoil: content.card.availableFoilness == true, intensity: surfaceIntensity),
          callToActionHorizontalOffset: 21.0,
          priceVisibility: .hidden,
          shadowConfiguration: .default
        ) { action in
          store.send(.descriptionCallToActionTapped, animation: .bouncy)
        }
        .modifier(CardTilt())
        .shadow(color: .black.opacity(0.36), radius: 16, y: 14)
        .onGeometryChange(for: CGRect.self) { proxy in
          proxy.frame(in: .global)
        } action: { newValue in
          if scrub?.selectedId == store.id || scrub?.cardId == store.id {
            scrub?.cardFrame = newValue
            // Only while the page sits at its top: a scrolled page's card is somewhere above the
            // screen, and a card flying to that is the card flying off the top.
            if isAtTop {
              scrub?.restingCardFrame = newValue
            }
          }
        }
        .modifier(LandingCardHide(scrub: scrub, cardId: store.id))
        .padding(
          EdgeInsets(top: 13, leading: 55, bottom: 34, trailing: 55)
        )
        // Exactly the page's width, so a landscape card and its padding (wider than the page on
        // a phone) can't widen the stack and, through `maxWidth`, grow the card again.
        .frame(width: maxWidth)
        .zIndex(1)
        
        Group {
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
        
        if showsSections {
        Group {
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
        .transition(.opacity)
        }
        }
        .modifier(LandingCardHide(scrub: scrub, cardId: store.id, untilPageShown: true))
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
    .scrollEdgeEffectStyle(.soft, for: .bottom)
    .onScrollGeometryChange(for: Bool.self) { geometry in
      geometry.contentOffset.y + geometry.contentInsets.top < 1
    } action: { _, newValue in
      isAtTop = newValue
    }
    .scrollDisabled(scrub?.isLanding == true && scrub?.cardId == store.id)
    .scrollPosition($scrollPosition)
    .onAppear {
      scrollPosition.scrollTo(edge: .top)
    }
    .onScrollVisibilityChange(threshold: 0.01) { isVisible in
      if isVisible == false {
        scrollPosition.scrollTo(edge: .top)
      }
    }
    .accessibilityIdentifier("cardDetail.scroll")
    // The reveal waits a beat and then runs in its own transaction. Landing hands the card over and
    // unhides the image in one frame, and an animation asked for in that same frame is flattened by
    // the hide's own instant animation.
    .task(id: isSurfaceHidden) {
      if isSurfaceHidden {
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
          surfaceIntensity = 0
        }
        return
      }
      guard surfaceIntensity < 1 else { return }
      try? await Task.sleep(for: .milliseconds(220))
      guard Task.isCancelled == false else { return }
      withAnimation(.easeOut(duration: 0.9)) {
        surfaceIntensity = 1
      }
    }
    .task(priority: .background) {
      // The page loads the moment the pager shows it. SwiftUI starts this task inside the update
      // that first shows the page, and a send has no suspension point, so without the yield the
      // send and its state changes land in that frame.
      await Task.yield()
      guard Task.isCancelled == false else { return }
      await scrub?.waitUntilSettled()
      guard Task.isCancelled == false else { return }
      if showsSections == false {
        withAnimation(.easeOut(duration: 0.25)) {
          showsSections = true
        }
      }
      await store.send(.viewAppeared).finish()
    }
    .background {
      ZStack {
        // Only the face on show gets a backdrop. Flipping swaps it with a crossfade, instead of
        // keeping both faces' images loaded and blurred with one of them at zero opacity.
        if let faceDirection {
          let url = content.card.getImageURL(type: .normal, getSecondFace: faceDirection == .back)
          backdrop(for: url)
            .modifier(LandingCardHide(scrub: scrub, cardId: store.id, untilPageShown: true))
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
