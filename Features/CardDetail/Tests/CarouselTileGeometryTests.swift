@testable import CardDetail
import Foundation
import Testing

/// A 248pt strip with 56pt ends curling round a quarter circle, about what it gets on a phone. A
/// card's frame in the scroll view starts at 0 when it is centred under the glass, and every slot is
/// 48pt.
struct CarouselTileGeometryTests {
  private let scrollWidth: CGFloat = 248
  private let zone: CGFloat = 56
  private let radius: CGFloat = 2 * 56 / .pi

  private func tile(at minX: CGFloat, parting: CGFloat = 12) -> CarouselTileGeometry {
    CarouselTileGeometry(
      frame: CGRect(x: minX, y: 0, width: 48, height: 48),
      parting: parting,
      scrollWidth: scrollWidth,
      zone: zone,
      radius: radius
    )
  }

  // MARK: - The card under the glass

  @Test func whenCentred_shouldSitInTheMiddleOfTheStrip() {
    let centred = tile(at: 0)

    #expect(centred.minX == 100)
    #expect(centred.minX + 24 == scrollWidth / 2)
  }

  @Test func whenCentred_shouldNotLeanOrCurl() {
    let centred = tile(at: 0)

    #expect(centred.lean == 0)
    #expect(centred.leanedMinX == centred.minX)
    #expect(centred.depth == 0)
    #expect(centred.bend == 0)
    #expect(centred.curl == 0)
  }

  @Test func whenCentred_shouldHaveTheLensAtItsMiddle() {
    let centred = tile(at: 0)

    #expect(centred.lensCenter == 24)
    #expect(centred.isNearLens)
    #expect(centred.isInEndZone == false)
  }

  // MARK: - Parting

  @Test func whenNextToTheCentre_shouldLeanAwayByTheWholeParting() {
    #expect(tile(at: 48).lean == 12)
    #expect(tile(at: -48).lean == -12)
    #expect(tile(at: 48).leanedMinX == tile(at: 48).minX + 12)
  }

  @Test func whenFurtherOut_shouldLeanNoFurtherThanTheParting() {
    #expect(tile(at: 96).lean == 12)
    #expect(tile(at: 144).lean == 12)
    #expect(tile(at: -96).lean == -12)
    #expect(tile(at: -144).lean == -12)
  }

  @Test func whenBetweenTheCentreAndTheNextSlot_shouldLeanInProportion() {
    // Mid-scrub a card sits part of the way between slots, and the lean ramps up with it.
    #expect(tile(at: 12).lean == 3)
    #expect(tile(at: 24).lean == 6)
    #expect(tile(at: 36).lean == 9)
    #expect(tile(at: -24).lean == -6)
  }

  @Test(arguments: [-144, -96, -48, -24, 0, 24, 48, 96, 144] as [CGFloat])
  func whenScrubbing_shouldNotLean(minX: CGFloat) {
    // The strip parts only once it has settled, so it runs on its even spacing under the finger.
    let scrubbed = tile(at: minX, parting: 0)

    #expect(scrubbed.lean == 0)
    #expect(scrubbed.leanedMinX == scrubbed.minX)
  }

  @Test func whenThePartingIsHalfWayIn_shouldLeanHalfAsFar() {
    // The parting animates, stepped frame by frame through the effect.
    #expect(tile(at: 48, parting: 6).lean == 6)
    #expect(tile(at: -96, parting: 6).lean == -6)
  }

  // MARK: - Curling round the ends

  @Test func whenInTheFlatMiddle_shouldNotCurl() {
    for minX: CGFloat in [-48, -24, 0, 24, 48] {
      let flat = tile(at: minX)

      #expect(flat.depth == 0, "at \(minX)")
      #expect(flat.curl == 0, "at \(minX)")
    }
  }

  @Test func whenPastTheRightEndZone_shouldCurlMoreTheFurtherOutItIs() {
    let near = tile(at: 96)
    let far = tile(at: 144)

    #expect(near.depth == 40)
    #expect(near.depth < far.depth)
    #expect(near.curl < 0)
    #expect(far.curl < near.curl)
  }

  @Test func whenPastTheLeftEndZone_shouldCurlMoreTheFurtherOutItIs() {
    let near = tile(at: -96)
    let far = tile(at: -144)

    #expect(near.depth == 40)
    #expect(near.depth < far.depth)
    #expect(near.curl > 0)
    #expect(far.curl > near.curl)
  }

  @Test func whenCurling_shouldMirrorBetweenTheEnds() {
    #expect(abs(tile(at: 96).curl + tile(at: -96).curl) < 0.000_1)
    #expect(abs(tile(at: 144).curl + tile(at: -144).curl) < 0.000_1)
  }

  @Test func whenCurling_shouldPullTheCardInByTheArcItHasWrappedRound() {
    // Wrapped round the bend, the card only reaches out as far as the arc's sine, so it moves in
    // by the rest of its depth.
    let near = tile(at: 96)

    #expect(abs(near.bend - 40 / radius) < 0.000_1)
    #expect(abs(near.curl + (40 - radius * sin(40 / radius))) < 0.000_1)
  }

  @Test func whenPastAQuarterTurn_shouldStopBending() {
    let far = tile(at: 144)

    #expect(far.bend == CGFloat.pi / 2)
    #expect(abs(far.curl + (far.depth - radius)) < 0.000_1)
  }

  // MARK: - Which shaders run

  @Test func whenOneSlotFromTheGlass_shouldStillBeMagnified() {
    // Mid-scrub the glass is over two cards at once.
    #expect(tile(at: 48).isNearLens)
    #expect(tile(at: -48).isNearLens)
    #expect(tile(at: 72, parting: 0).isNearLens)
  }

  @Test func whenWellClearOfTheGlass_shouldNotBeMagnified() {
    #expect(tile(at: 144).isNearLens == false)
    #expect(tile(at: -144).isNearLens == false)
  }

  @Test func whenReachingIntoEitherEnd_shouldBend() {
    #expect(tile(at: 48).isInEndZone)
    #expect(tile(at: -48).isInEndZone)
    #expect(tile(at: 144).isInEndZone)
    #expect(tile(at: -144).isInEndZone)
  }

  @Test func whenClearOfBothEnds_shouldNotBend() {
    let wideStrip = CarouselTileGeometry(
      frame: CGRect(x: 48, y: 0, width: 48, height: 48),
      parting: 0,
      scrollWidth: 400,
      zone: zone,
      radius: radius
    )

    #expect(tile(at: 0).isInEndZone == false)
    #expect(wideStrip.isInEndZone == false)
  }
}
