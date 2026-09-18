@testable import CardDetail
import DesignComponents
import Foundation
import Testing

struct ScrubPreviewLayoutTests {
  // A 402pt phone: the pager under a 62pt top inset, and the strip in the bottom bar.
  private let page = CGRect(x: 0, y: 62, width: 402, height: 750)
  private let carousel = CGRect(x: 90, y: 790, width: 222, height: 48)

  private func makeLayout(isLandscape: Bool = false) -> ScrubPreviewLayout {
    ScrubPreviewLayout(page: page, carousel: carousel, isLandscape: isLandscape)
  }

  // MARK: - Size

  @Test func whenPortrait_shouldSizeTheCardAsThePageDoes() {
    #expect(makeLayout().configuration == .detailPage(isLandscape: false, pageWidth: 402))
    #expect(makeLayout().configuration.size == CGSize(width: 268, height: 374))
  }

  @Test func whenLandscape_shouldSizeTheCardAsThePageDoes() {
    #expect(makeLayout(isLandscape: true).configuration == .detailPage(isLandscape: true, pageWidth: 402))
    #expect(makeLayout(isLandscape: true).configuration.size == CGSize(width: 335, height: 240))
  }

  @Test(arguments: [320.0, 402.0, 440.0] as [CGFloat])
  func whenHovering_shouldBeAFixedWidthWhateverThePage(pageWidth: CGFloat) {
    let page = CGRect(x: 0, y: 0, width: pageWidth, height: 800)
    let portrait = ScrubPreviewLayout(page: page, carousel: carousel, isLandscape: false)
    let landscape = ScrubPreviewLayout(page: page, carousel: carousel, isLandscape: true)

    #expect(abs(portrait.configuration.size.width * portrait.hoverScale - 183) < 0.000_1)
    #expect(abs(landscape.configuration.size.width * landscape.hoverScale - 244) < 0.000_1)
  }

  @Test(arguments: [false, true])
  func whenOnTheGlass_shouldShrinkToTheGlassesHeight(isLandscape: Bool) {
    let layout = makeLayout(isLandscape: isLandscape)

    #expect(abs(layout.configuration.size.height * layout.thumbnailScale - 34) < 0.000_1)
  }

  // MARK: - Place

  @Test func whenOnTheGlass_shouldSitInTheMiddleOfTheStrip() {
    #expect(makeLayout().thumbnailCenter == CGPoint(x: carousel.midX, y: carousel.midY))
  }

  @Test(arguments: [false, true])
  func whenHovering_shouldFloat14ptAboveTheBar(isLandscape: Bool) {
    let layout = makeLayout(isLandscape: isLandscape)
    let hoveredHeight = layout.configuration.size.height * layout.hoverScale

    #expect(layout.hoverCenter.x == carousel.midX)
    #expect(abs(layout.hoverCenter.y + hoveredHeight / 2 - (carousel.minY - 14)) < 0.000_1)
  }

  @Test func whenThePageHasNotMeasuredItsCard_shouldLandWhereThePageLaysItOut() {
    let layout = makeLayout()

    #expect(layout.landedCenter(restingCardFrame: .zero) == layout.pageCardCenter)
    #expect(layout.pageCardCenter.x == page.midX)
    #expect(layout.pageCardCenter.y - layout.configuration.size.height / 2 == page.minY + 13)
  }

  @Test func whenThePageHasMeasuredItsCard_shouldLandOnIt() {
    // The page's own measure wins, so the flight ends exactly on the card it hands over to.
    let resting = CGRect(x: 67, y: 81, width: 268, height: 374)

    #expect(makeLayout().landedCenter(restingCardFrame: resting) == CGPoint(x: resting.midX, y: resting.midY))
  }

  // MARK: - Following the finger

  @Test func whenTheFingerIsOnTheBarsCentre_shouldNotFollow() {
    #expect(makeLayout().follow(CGPoint(x: carousel.midX, y: carousel.midY)) == .zero)
  }

  @Test func whenTheFingerIsNearTheCentre_shouldFollowAQuarterOfTheWay() {
    let follow = makeLayout().follow(CGPoint(x: carousel.midX + 40, y: carousel.midY - 16))

    #expect(follow == CGSize(width: 10, height: -4))
  }

  @Test func whenTheFingerIsFarOut_shouldFollowNoFurtherThanItsReach() {
    let layout = makeLayout()

    #expect(layout.follow(CGPoint(x: carousel.maxX + 200, y: carousel.maxY + 200)) == CGSize(width: 24, height: 8))
    #expect(layout.follow(CGPoint(x: carousel.minX - 200, y: carousel.minY - 200)) == CGSize(width: -24, height: -8))
  }

  // MARK: - Leaning into the scrub

  @Test func whenTheFingerIsStill_shouldNotLean() {
    #expect(ScrubPreviewLayout.lean(forVelocity: 0) == 0)
  }

  @Test func whenTheFingerIsMoving_shouldLeanWithIt() {
    #expect(ScrubPreviewLayout.lean(forVelocity: 450) == 5)
    #expect(ScrubPreviewLayout.lean(forVelocity: -900) == -10)
  }

  @Test func whenTheFingerIsFast_shouldLeanNoFurtherThan16Degrees() {
    #expect(ScrubPreviewLayout.lean(forVelocity: 4_000) == 16)
    #expect(ScrubPreviewLayout.lean(forVelocity: -4_000) == -16)
  }
}
