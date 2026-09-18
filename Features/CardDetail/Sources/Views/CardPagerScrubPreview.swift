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
      let carousel = scrub.carouselFrame
      let isVisible = scrub.isHovering || scrub.isLanding
      let configuration = CardLayoutConfiguration(
        rotation: scrub.isLandscape ? .landscape : .portrait,
        maxWidth: ((scrub.isLandscape ? 2.5 : 2.0) / 3.0 * page.width).rounded()
      )
      let size = configuration.size
      let hoverScale = (scrub.isLandscape ? 244.0 : 183.0) / size.width
      let thumbnailScale = 34.0 / size.height
      let hoverCenter = CGPoint(x: carousel.midX, y: carousel.minY - 14 - size.height * hoverScale / 2)
      let thumbnailCenter = CGPoint(x: carousel.midX, y: carousel.midY)
      let landedCenter = scrub.isFlying && scrub.restingCardFrame.width > 0
        ? CGPoint(x: scrub.restingCardFrame.midX, y: scrub.restingCardFrame.midY)
        : CGPoint(x: page.midX, y: page.minY + 13 + size.height / 2)
      let follow = scrub.isHovering
        ? CGSize(
          width: min(max((scrub.location.x - carousel.midX) * 0.25, -24), 24),
          height: min(max((scrub.location.y - carousel.midY) * 0.25, -8), 8)
        )
        : .zero
      let lean = scrub.isHovering ? min(max(scrub.velocity / 90, -16), 16) : 0

      ZStack {
        if let outgoing = scrub.outgoing, scrub.outgoingFrame.width > 0 {
          let outgoingConfiguration = CardLayoutConfiguration(
            rotation: scrub.outgoingIsLandscape ? .landscape : .portrait,
            maxWidth: ((scrub.outgoingIsLandscape ? 2.5 : 2.0) / 3.0 * page.width).rounded()
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
          radius: scrub.isHovering ? 28 / hoverScale : 16,
          y: scrub.isHovering ? 22 / hoverScale : 14
        )
        .scaleEffect(scrub.isFlying ? 1 : (scrub.isHovering ? hoverScale : thumbnailScale))
        .opacity(isVisible ? 1 : 0)
        .animation(scrub.isHovering ? .interactiveSpring(response: 0.3, dampingFraction: 0.8) : .easeOut(duration: 0.2)) { content in
          content.offset(follow)
        }
        .position(scrub.isFlying ? landedCenter : (scrub.isHovering ? hoverCenter : thumbnailCenter))

      }
      .allowsHitTesting(false)
      .accessibilityHidden(true)
    }
  }
}
