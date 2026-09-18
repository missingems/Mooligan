@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

/// Which page a scrub lands on when it is let go.
@MainActor struct CardPagerFeatureLandingTargetTests {
  private let firstCard = Card.mock(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
  private let secondCard = Card.mock(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002"))

  private func pager(selecting selected: Card) -> CardPagerFeature.State {
    CardPagerFeature.State(
      cardDetails: [CardInfo(card: firstCard), CardInfo(card: secondCard)],
      initialSelectedCard: selected,
      queryType: .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
    )
  }

  @Test func whenLetGoOverAnotherCard_shouldLandOnItsPage() {
    let target = pager(selecting: firstCard).landingTarget(secondCard.id)

    #expect(target?.id == secondCard.id)
  }

  @Test func whenLetGoOverTheCardAlreadyOnShow_shouldNotLand() {
    // The hover card only goes back into the strip, with no flight and no page hidden.
    #expect(pager(selecting: firstCard).landingTarget(firstCard.id) == nil)
  }

  @Test func whenNothingIsUnderTheGlass_shouldNotLand() {
    #expect(pager(selecting: firstCard).landingTarget(nil) == nil)
  }

  @Test func whenTheCardIsNotInThePager_shouldNotLand() {
    let missing = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

    #expect(pager(selecting: firstCard).landingTarget(missing) == nil)
  }

  @Test func whenNothingIsSelected_shouldLandOnAnyCard() {
    var state = pager(selecting: firstCard)
    state.selectedId = nil

    #expect(state.landingTarget(firstCard.id)?.id == firstCard.id)
  }
}
