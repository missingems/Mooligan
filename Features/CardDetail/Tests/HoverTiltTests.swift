@testable import CardDetail
import SwiftUI
import Testing

/// The sway eases in and out with the hover through the amount, which SwiftUI steps here.
@MainActor struct HoverTiltTests {
  @Test func animatableData_shouldReadAndWriteTheAmount() {
    var tilt = HoverTilt(amount: 1, isActive: true) { _ in EmptyView() }
    #expect(tilt.animatableData == 1)

    tilt.animatableData = 0.25

    #expect(tilt.amount == 0.25)
    #expect(tilt.isActive)
  }
}
