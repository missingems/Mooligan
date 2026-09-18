import SwiftUI

struct LandingCardHide: ViewModifier {
  let scrub: CarouselScrub?
  let cardId: UUID
  var untilPageShown = false

  func body(content: Self.Content) -> some View {
    let isHidden = scrub?.isLanding == true
      && scrub?.cardId == cardId
      && (untilPageShown == false || scrub?.isPageHidden == true)

    content
      .opacity(isHidden ? 0 : 1)
      .animation(untilPageShown && isHidden == false ? .easeOut(duration: 0.65).delay(0.12) : nil, value: isHidden)
      .onChange(of: isHidden, initial: true) { _, newValue in
        if untilPageShown, newValue {
          scrub?.pageReadyId = cardId
        }
      }
  }
}
