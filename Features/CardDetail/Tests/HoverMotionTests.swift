@testable import CardDetail
import Foundation
import Testing

struct HoverMotionTests {
  private let moments: [TimeInterval] = stride(from: 0.0, through: 12.0, by: 0.05).map { 800_000_000 + $0 }

  @Test func whenNotHovering_shouldHoldStill() {
    // The timeline pauses at zero, so the card must be at rest there whatever the clock says.
    for time in moments {
      let motion = HoverMotion(time: time, amount: 0)

      #expect(motion.pose == .zero)
      #expect(motion.rotation == 0)
      #expect(motion.lift == 0)
    }
  }

  @Test func whenHovering_shouldStayWithinAGentleSway() {
    for time in moments {
      let motion = HoverMotion(time: time, amount: 1)

      #expect(abs(motion.pose.x) <= 10)
      #expect(abs(motion.pose.y) <= 7)
      #expect(abs(motion.rotation) <= 2)
      #expect(abs(motion.lift) <= 6)
    }
  }

  @Test func whenHovering_shouldActuallyMove() {
    let poses = Set(moments.map { HoverMotion(time: $0, amount: 1).pose.x })

    #expect(poses.count > 1)
  }

  @Test func whenEasingInOrOut_shouldScaleTheWholeMotion() {
    // The amount animates between 0 and 1 as the hover starts and ends, and the sway follows it.
    for time in moments {
      let full = HoverMotion(time: time, amount: 1)
      let half = HoverMotion(time: time, amount: 0.5)

      #expect(abs(half.pose.x - full.pose.x / 2) < 0.000_1)
      #expect(abs(half.pose.y - full.pose.y / 2) < 0.000_1)
      #expect(abs(half.rotation - full.rotation / 2) < 0.000_1)
      #expect(abs(half.lift - full.lift / 2) < 0.000_1)
    }
  }
}
