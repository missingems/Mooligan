import DesignComponents
import SwiftUI

public struct CardPagerScrubPreview: View {
  private let scrub: CarouselScrub

  public init(scrub: CarouselScrub) {
    self.scrub = scrub
  }

  public var body: some View {
    if let image = scrub.image, scrub.pageFrame.width > 0 {
      let page = scrub.pageFrame
      let layout = ScrubPreviewLayout(page: page, carousel: scrub.carouselFrame, isLandscape: scrub.isLandscape)
      let isVisible = scrub.isHovering || scrub.isLanding
      let configuration = layout.configuration
      let size = configuration.size
      // The resting frame and the finger are read only while they matter, so moving them does not
      // redraw the preview the rest of the time.
      let landedCenter = scrub.isFlying
        ? layout.landedCenter(restingCardFrame: scrub.restingCardFrame)
        : layout.pageCardCenter
      let follow = scrub.isHovering ? layout.follow(scrub.location) : .zero
      let lean = scrub.isHovering ? ScrubPreviewLayout.lean(forVelocity: scrub.velocity) : 0

      ZStack {
        if let outgoing = scrub.outgoing, scrub.outgoingFrame.width > 0 {
          let outgoingConfiguration = CardLayoutConfiguration.detailPage(
            isLandscape: scrub.outgoingIsLandscape,
            pageWidth: page.width
          )

          CardView(
            displayableCard: outgoing,
            layoutConfiguration: outgoingConfiguration,
            surface: CardSurface(isFoil: scrub.outgoingIsFoil),
            priceVisibility: .hidden
          )
          .modifier(CardTilt())
          .shadow(color: .black.opacity(0.36), radius: 16, y: 14)
          .scaleEffect(scrub.isOutgoingHidden ? 0.94 : 1)
          .opacity(scrub.isOutgoingHidden ? 0 : 1)
          .position(x: scrub.outgoingFrame.midX, y: scrub.outgoingFrame.midY)
        }

        HoverTilt(amount: scrub.isHovering ? 1 : 0, isActive: isVisible) { pose in
          ZStack {
            if scrub.isLandscape == false {
              CardView(
                displayableCard: .single(displayingImageURL: image.frontFaceURL, id: image.id),
                layoutConfiguration: configuration,
                priceVisibility: .hidden,
                downsampleWidth: 31.5
              )
              .equatable()
            }

            // The face the strip shows, and no call to action with it: the card is along for the
            // ride, not something to flip, and a transform card was animating its turn mid-flight.
            CardView(
              displayableCard: .single(displayingImageURL: image.frontFaceURL, id: image.id),
              layoutConfiguration: configuration,
              surface: CardSurface(isFoil: scrub.isFoil, isActive: isVisible, pose: pose, intensity: scrub.isFlying ? 0 : 1),
              priceVisibility: .hidden,
              shadowConfiguration: .default
            )
            // The card this one flies into wears the same effect, lit from a different place. Two
            // of them on screen at once read as two cards, so this one gives its up on the way in
            // and the page's fades up once it has landed.
            .animation(.easeOut(duration: 0.26), value: scrub.isFlying)
          }
          .frame(width: size.width, height: size.height)
        }
        .animation(scrub.isHovering ? .smooth(duration: 0.35) : .easeOut(duration: 0.2)) { content in
          content
            .rotation3DEffect(.degrees(lean), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .rotationEffect(.degrees(lean * -0.3))
        }
        .shadow(
          color: .black.opacity(scrub.isHovering ? 0.5 : (scrub.isFlying ? 0.36 : 0)),
          radius: scrub.isHovering ? 28 / layout.hoverScale : 16,
          y: scrub.isHovering ? 22 / layout.hoverScale : 14
        )
        .scaleEffect(scrub.isFlying ? 1 : (scrub.isHovering ? layout.hoverScale : layout.thumbnailScale))
        .opacity(isVisible ? 1 : 0)
        .animation(scrub.isHovering ? .interactiveSpring(response: 0.3, dampingFraction: 0.8) : .easeOut(duration: 0.2)) { content in
          content.offset(follow)
        }
        .position(scrub.isFlying ? landedCenter : (scrub.isHovering ? layout.hoverCenter : layout.thumbnailCenter))

      }
      .allowsHitTesting(false)
      .accessibilityHidden(true)
    }
  }
}
