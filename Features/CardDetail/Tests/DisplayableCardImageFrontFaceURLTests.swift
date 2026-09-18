@testable import CardDetail
import Foundation
import Networking
import Testing

/// The strip and the hover card always show a card's front, whichever face its page is turned to.
struct DisplayableCardImageFrontFaceURLTests {
  private let frontURL = URL(string: "https://cards.scryfall.io/normal/front/a/b/ab.jpg")!
  private let backURL = URL(string: "https://cards.scryfall.io/normal/back/a/b/ab.jpg")!

  @Test func whenSingleFaced_shouldBeItsOnlyImage() {
    let image = DisplayableCardImage.single(displayingImageURL: frontURL, id: "single")

    #expect(image.frontFaceURL == frontURL)
  }

  @Test(arguments: [MagicCardFaceDirection.front, .back])
  func whenFlippable_shouldBeItsOneImageWhicheverWayUp(direction: MagicCardFaceDirection) {
    // A flip card prints both halves on one image, and flipping it turns that image upside down.
    let image = DisplayableCardImage.flippable(
      direction: direction,
      displayingImageURL: frontURL,
      callToActionIconName: "arrow.trianglehead.clockwise.rotate.90",
      id: "flippable"
    )

    #expect(image.frontFaceURL == frontURL)
  }

  @Test func whenTransformableShowingItsFront_shouldBeTheFront() {
    let image = DisplayableCardImage.transformable(
      direction: .front,
      frontImageURL: frontURL,
      backImageURL: backURL,
      callToActionIconName: "arrow.left.arrow.right",
      id: "transformable"
    )

    #expect(image.frontFaceURL == frontURL)
  }

  @Test func whenTransformableShowingItsBack_shouldStillBeTheFront() {
    let image = DisplayableCardImage.transformable(
      direction: .back,
      frontImageURL: frontURL,
      backImageURL: backURL,
      callToActionIconName: "arrow.left.arrow.right",
      id: "transformable"
    )

    #expect(image.frontFaceURL == frontURL)
  }
}
