@testable import CardDetail
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct ContentStateTests {
  private let card = Card.mock()

  @Test func whenDataSourceHasCards_shouldExposeIt() {
    let dataSource = CardDataSource(cards: [card], hasNextPage: false, total: 1)
    let state = Content.State.data(dataSource)

    #expect(state.value == dataSource)
    #expect(state.isInitial == false)
  }

  @Test func whenDataSourceIsEmpty_shouldReadAsAbsent() {
    let state = Content.State.data(CardDataSource(cards: [], hasNextPage: false, total: 0))

    // A fetch that found nothing still reports `.data`, so an empty source has to
    // read as absent or the view builds an empty section for it.
    #expect(state.value == nil)
    #expect(state.isInitial == false)
  }

  @Test func whenInitialWithACard_shouldExposeSingleCardDataSource() {
    let state = Content.State.initial(card)

    #expect(state.value?.cardDetails.count == 1)
    #expect(state.value?.cardDetails.first?.card == card)
    #expect(state.value?.hasNextPage == false)
    #expect(state.value?.total == 1)
    #expect(state.isInitial)
  }

  @Test func whenInitialWithoutACard_shouldReadAsAbsent() {
    let state = Content.State.initial(nil)

    #expect(state.value == nil)
    #expect(state.isInitial)
  }
}

@MainActor struct ContentTests {
  private let card = Card.mock()

  private var queryType: QueryType {
    .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
  }

  private var content: Content {
    Content(card: card, queryType: queryType)
  }

  @Test func whenBuiltFromASearch_shouldNotHaveASetIcon() {
    #expect(content.setIconURL == nil)
  }

  @Test func whenBuiltFromASet_shouldTakeTheSetIcon() {
    let set = MockGameSetRequestClient.mockSets[0]
    let content = Content(
      card: card,
      queryType: .querySet(set, SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
    )

    #expect(content.setIconURL == URL(string: set.iconSvgUri))
  }

  @Test func whenBuilt_shouldStartVariantsWithTheCardItself() {
    #expect(content.variants.state.isInitial)
    #expect(content.variants.state.value?.cardDetails.count == 1)
  }

  @Test func whenBuilt_shouldStartRelatedSectionsEmpty() {
    #expect(content.relatedTokens?.state.value == nil)
    #expect(content.relatedComboPieces?.state.value == nil)
    #expect(content.relatedMeldPieces?.state.value == nil)
    #expect(content.relatedMeldResult?.state.value == nil)
  }

  @Test func whenCardHasNoColourIdentity_shouldReportColourless() {
    #expect(content.getColorIdentity() == ["{C}"])
  }

  @Test func whenBuildingDescriptions_shouldReturnOneForASingleFacedCard() {
    #expect(content.getDescriptions().count == 1)
  }
}
