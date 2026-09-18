@testable import CardDetail
import Foundation
import Testing

/// The rule `LandingCardHide` and the page's surface read: which parts of a page stay out of sight
/// while the hover card lands on it.
@MainActor struct LandingCardHideTests {
  private let cardId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
  private let otherCardId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

  private func makeScrub(isLanding: Bool, landingCardId: UUID?, isPageHidden: Bool) -> CarouselScrub {
    let scrub = CarouselScrub()
    scrub.isLanding = isLanding
    scrub.cardId = landingCardId
    scrub.isPageHidden = isPageHidden
    return scrub
  }

  @Test(arguments: [false, true], [false, true])
  func whenNothingIsLanding_shouldHideNothing(untilPageShown: Bool, isPageHidden: Bool) {
    for landingCardId in [cardId, otherCardId, nil] {
      let scrub = makeScrub(isLanding: false, landingCardId: landingCardId, isPageHidden: isPageHidden)

      #expect(scrub.hidesLanding(of: cardId, untilPageShown: untilPageShown) == false)
    }
  }

  @Test(arguments: [false, true], [false, true])
  func whenAnotherCardIsLanding_shouldHideNothing(untilPageShown: Bool, isPageHidden: Bool) {
    for landingCardId in [otherCardId, nil] {
      let scrub = makeScrub(isLanding: true, landingCardId: landingCardId, isPageHidden: isPageHidden)

      #expect(scrub.hidesLanding(of: cardId, untilPageShown: untilPageShown) == false)
    }
  }

  @Test(arguments: [false, true])
  func whenThisCardIsLanding_shouldHideItsCardForTheWholeLanding(isPageHidden: Bool) {
    // The flying card stands in for the page's own until it has landed, even once the page shows.
    let scrub = makeScrub(isLanding: true, landingCardId: cardId, isPageHidden: isPageHidden)

    #expect(scrub.hidesLanding(of: cardId, untilPageShown: false))
    #expect(scrub.hidesLanding(of: cardId))
  }

  @Test func whenThisCardIsLanding_shouldHideTheRestOfThePageWhileThePageIsHidden() {
    let scrub = makeScrub(isLanding: true, landingCardId: cardId, isPageHidden: true)

    #expect(scrub.hidesLanding(of: cardId, untilPageShown: true))
  }

  @Test func whenThisCardIsLanding_shouldShowTheRestOfThePageOnceThePageIsShown() {
    // The page fades in as the card starts to fly, rather than after it has landed.
    let scrub = makeScrub(isLanding: true, landingCardId: cardId, isPageHidden: false)

    #expect(scrub.hidesLanding(of: cardId, untilPageShown: true) == false)
  }
}
