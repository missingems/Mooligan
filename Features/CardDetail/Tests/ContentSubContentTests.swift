@testable import CardDetail
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct ContentSubContentTests {
  @Test func whenItHoldsCards_shouldCountTheCardsHeldBeforeTheSuffix() {
    let subContent = Content.SubContent(
      state: .data(CardDataSource(
        cards: MockCardDetailRequestClient.generateMockCards(number: 3),
        hasNextPage: true,
        total: 10
      )),
      title: "Prints",
      subtitleSuffix: "Results"
    )

    // Counts what has loaded, not the total the search reported.
    #expect(subContent.subtitle == "3 Results")
  }

  @Test func whenItStartsFromTheCardOnShow_shouldCountThatOneCard() {
    let subContent = Content.SubContent(state: .initial(Card.mock()), title: "Prints", subtitleSuffix: "Results")

    #expect(subContent.subtitle == "1 Results")
  }

  @Test func whenItHasNothingYet_shouldCountZero() {
    let subContent = Content.SubContent(state: .initial(nil), title: "Tokens", subtitleSuffix: "Results")

    #expect(subContent.subtitle == "0 Results")
  }

  @Test func whenItsFetchFoundNothing_shouldCountZero() {
    let subContent = Content.SubContent(
      state: .data(CardDataSource(cards: [], hasNextPage: false, total: 0)),
      title: "Tokens",
      subtitleSuffix: "Results"
    )

    #expect(subContent.subtitle == "0 Results")
  }
}
