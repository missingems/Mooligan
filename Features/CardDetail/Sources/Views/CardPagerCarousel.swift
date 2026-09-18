import ComposableArchitecture
import DesignComponents
import Nuke
import SwiftUI
import VariableBlur

public struct CardPagerCarousel: View {
  @Bindable private var store: StoreOf<CardPagerFeature>
  @State private var centeredId: UUID?
  @State private var settle: Task<Void, Never>?
  @Environment(\.scenePhase) private var scenePhase
  private let scrub: CarouselScrub
  private let width: CGFloat
  
  public init(store: StoreOf<CardPagerFeature>, scrub: CarouselScrub, width: CGFloat) {
    self.store = store
    self.scrub = scrub
    self.width = width
  }
  
  public var body: some View {
    let width = width - 4
    let zone = 56.0
    let radius = 2 * zone / CGFloat.pi
    // The strip reaches a little way short of the bar's ends, so a card has finished curling out of
    // sight 5pt before the bar's rounded end and is never cut by it.
    let scrollWidth = width + 2 * (zone - radius) - 10
    
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 0) {
          ForEach(Array(store.cards.ids), id: \.self) { id in
            if let card = store.cards[id: id], let image = card.displayableCardImage {
              CarouselThumbnail(url: image.frontFaceURL, width: 44.0)
                .frame(width: 48.0, height: 48.0)
                .modifier(
                  CarouselTileEffect(
                    parting: scrub.isHovering ? 0.0 : 12.0,
                    scrollWidth: scrollWidth,
                    zone: zone,
                    radius: radius
                  )
                )
                .contentShape(.rect)
                .onTapGesture {
                  if scrub.isLanding {
                    var instant = Transaction()
                    instant.disablesAnimations = true
                    withTransaction(instant) {
                      scrub.endLanding()
                    }
                  }
                  store.selectedId = id
                }
                .accessibilityIdentifier("cardDetail.carousel.\(card.content.card.collectorNumber)")
                .id(id)
            }
          }
        }
        .scrollTargetLayout()
      }
      .contentMargins(.horizontal, max(0, (scrollWidth - 48.0) / 2), for: .scrollContent)
      .scrollTargetBehavior(.viewAligned(anchor: .center))
      .scrollPosition(id: $centeredId, anchor: .center)
      .gesture(CarouselThumbTracker(scrub: scrub))
      .sensoryFeedback(trigger: scrub.cardId) { _, _ in
        scrub.isHovering ? .selection : nil
      }
      .onScrollPhaseChange { _, newPhase in
        if newPhase == .interacting {
          settle?.cancel()
          beginScrub()
        } else if newPhase == .decelerating, scrub.isHovering,
                  max(abs(scrub.velocity), abs(scrub.releaseVelocity)) < 120 {
          // Let go of a still strip and the card goes at once, rather than waiting out the snap.
          // Anything with a throw in it skips this and lands from `.idle` below, once it has run out.
          // The speed is the finger's, from the tracker: the phase change's own velocity arrived
          // empty on a fast release, read as zero, and landed the card the finger had just left.
          land(centeredId ?? scrub.cardId)
        } else if newPhase == .idle, scrub.isHovering {
          settle = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(32))
            guard Task.isCancelled == false, scrub.isHovering else { return }
            land(centeredId ?? scrub.cardId)
          }
        } else if newPhase == .idle, scrub.isLanding == false, centeredId != store.selectedId {
          withAnimation(.smooth) {
            centeredId = store.selectedId
          }
        }
      }
      .onChange(of: centeredId) { _, newValue in
        if scrub.isHovering {
          show(newValue)
        }
      }
      .frame(width: scrollWidth, height: 48.0)
      .frame(width: width, height: 48.0)
      // The ends soften as the cards curl away. The package only blurs top-to-bottom, so each end is
      // a vertical blur turned on its side: laid out tall, rotated a quarter turn, then framed to
      // the width of the curl.
      .padding(.horizontal, 5)
      .overlay(alignment: .leading) {
        VariableBlurView(maxBlurRadius: 1.5, direction: .blurredTopClearBottom, startOffset: 0)
          .frame(width: 53, height: 34)
          .rotationEffect(.degrees(-90))
          .frame(width: 34, height: 53)
          .allowsHitTesting(false)
      }
      .overlay(alignment: .trailing) {
        VariableBlurView(maxBlurRadius: 1.5, direction: .blurredTopClearBottom, startOffset: 0)
          .frame(width: 53, height: 34)
          .rotationEffect(.degrees(90))
          .frame(width: 34, height: 53)
          .allowsHitTesting(false)
      }
      .clipShape(.capsule)
      .glassEffect(.regular.interactive(), in: .capsule)
      .overlay {
        CarouselLens(scrub: scrub)
      }
      .onGeometryChange(for: CGRect.self) { geometry in
        geometry.frame(in: .global)
      } action: { newValue in
        scrub.carouselFrame = newValue
      }
      .task(id: width) {
        centeredId = store.selectedId
        proxy.scrollTo(store.selectedId, anchor: .center)
        try? await Task.sleep(for: .milliseconds(80))
        guard Task.isCancelled == false, scrub.isHovering == false, scrub.isLanding == false else { return }
        proxy.scrollTo(store.selectedId, anchor: .center)
      }
      .onChange(of: scenePhase) { _, newValue in
        guard newValue == .active, scrub.isHovering == false, scrub.isLanding == false else { return }
        centeredId = store.selectedId
      }
      .onChange(of: store.selectedId) { _, newValue in
        withAnimation(.smooth) {
          centeredId = newValue
        }
      }
      .onChange(of: scrub.isHovering || scrub.isLanding) { _, isScrubbing in
        guard isScrubbing == false, centeredId != store.selectedId else { return }
        withAnimation(.smooth) {
          centeredId = store.selectedId
        }
      }
      .accessibilityIdentifier("cardDetail.carousel")
    }
  }
  
  private func show(_ id: UUID?) {
    guard let id, let card = store.cards[id: id], id != scrub.cardId || card.displayableCardImage != scrub.image else { return }
    scrub.image = card.displayableCardImage
    scrub.isLandscape = card.content.card.isLandscape
    scrub.isFoil = card.content.card.availableFoilness == true
    scrub.cardId = id
  }
  
  private func beginScrub() {
    scrub.endLanding()
    show(centeredId ?? store.selectedId)
    withAnimation(.smooth(duration: 0.2)) {
      scrub.isHovering = true
    }
  }
  
  private func land(_ id: UUID?) {
    guard let id, id != store.selectedId, let card = store.cards[id: id] else {
      withAnimation(.smooth(duration: 0.2)) {
        scrub.isHovering = false
      }
      return
    }
    
    let backdrop = ImageRequest(
      url: card.content.card.getImageURL(
        type: .normal,
        getSecondFace: card.displayableCardImage?.faceDirection == .back
      ),
      processors: [ArtCropImageProcessor()]
    )
    
    var instant = Transaction()
    instant.disablesAnimations = true
    
    let outgoing = store.selectedId.flatMap { store.cards[id: $0] }
    show(id)
    
    withTransaction(instant) {
      scrub.outgoing = outgoing?.displayableCardImage
      scrub.outgoingIsLandscape = outgoing?.content.card.isLandscape == true
      scrub.outgoingIsFoil = outgoing?.content.card.availableFoilness == true
      scrub.outgoingFrame = scrub.cardFrame
      scrub.landingBackdrop = outgoing.map {
        $0.content.card.getImageURL(type: .normal, getSecondFace: $0.displayableCardImage?.faceDirection == .back)
      } ?? nil
      scrub.isOutgoingHidden = false
      scrub.pageReadyId = nil
      scrub.isPageHidden = true
      scrub.isLanding = true
      store.selectedId = id
    }
    
    scrub.landing?.cancel()
    scrub.landing = Task { @MainActor in
      let prefetch = Task {
        _ = try? await ImagePipeline.shared.image(for: backdrop)
      }
      
      await withTaskCancellationHandler {
        for _ in 0..<14 {
          if scrub.pageReadyId == id { break }
          try? await Task.sleep(for: .milliseconds(8))
        }
        guard Task.isCancelled == false else { return }
        withAnimation(.snappy(duration: 0.3)) {
          scrub.isHovering = false
          scrub.isFlying = true
        }
        scrub.isPageHidden = false
        withAnimation(.easeIn(duration: 0.32)) {
          scrub.isOutgoingHidden = true
        }
        
        try? await Task.sleep(for: .milliseconds(380))
        guard Task.isCancelled == false else { return }
        withTransaction(instant) {
          scrub.isLanding = false
          scrub.isFlying = false
          scrub.outgoing = nil
        }
        
        try? await Task.sleep(for: .milliseconds(450))
        guard Task.isCancelled == false else { return }
        scrub.landingBackdrop = nil
        scrub.landing = nil
      } onCancel: {
        prefetch.cancel()
      }
    }
  }
}


