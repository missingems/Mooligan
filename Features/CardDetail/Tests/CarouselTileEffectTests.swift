@testable import CardDetail
import Foundation
import Testing

/// The effect steps the parting itself, frame by frame, so the offset and the shaders are worked out
/// from the same value. Animated from outside, the cards either side of the glass vanished for the
/// whole landing.
@MainActor struct CarouselTileEffectTests {
  @Test func animatableData_shouldReadAndWriteTheParting() {
    var effect = CarouselTileEffect(parting: 12, scrollWidth: 248, zone: 56, radius: 2 * 56 / .pi)
    #expect(effect.animatableData == 12)

    effect.animatableData = 6

    #expect(effect.parting == 6)
    #expect(effect.scrollWidth == 248)
    #expect(effect.zone == 56)
  }
}
