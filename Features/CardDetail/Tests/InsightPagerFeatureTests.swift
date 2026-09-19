@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct InsightPagerFeatureTests {
  private let card = Card.mock(name: "Maha, Its Feathers Night", collectorNumber: "100")
  private let row: [InformationWidget] = [
    .set(code: "blb", rarity: .mythic, iconURL: nil),
    .collectorNumber("100"),
    .manaValue("5.0"),
  ]

  private func makeStore(opening: InformationWidget, writer: any CardInsightWriter) -> TestStoreOf<InsightPagerFeature> {
    TestStore(
      initialState: InsightPagerFeature.State(widgets: row, selected: opening, card: card, faceDirection: nil)
    ) {
      InsightPagerFeature()
    } withDependencies: {
      $0.cardInsightWriter = writer
    }
  }

  @Test func opening_shouldHoldEveryTileInTheRowsOrderOnTheOneTapped() {
    let state = InsightPagerFeature.State(widgets: row, selected: row[1], card: card, faceDirection: nil)

    #expect(state.pages.ids.elements == row)
    #expect(state.selection == row[1])
    #expect(state.opened == row[1])
    #expect(state.pages.allSatisfy { $0.elaboration == .pending })
  }

  @Test func appearing_shouldStartWritingOnlyThePageOnShow() async {
    let store = makeStore(opening: row[1], writer: MockCardInsightWriter(snapshots: ["Number 100"]))

    await store.send(.appeared)
    await store.receive(\.pages[id: row[1]].task) {
      $0.pages[id: row[1]]?.elaboration = .writing("")
    }
    await store.receive(\.pages[id: row[1]].elaborationUpdated) {
      $0.pages[id: row[1]]?.elaboration = .writing("Number 100")
    }
    await store.receive(\.pages[id: row[1]].elaborationEnded) {
      $0.pages[id: row[1]]?.elaboration = .written("Number 100")
    }

    #expect(store.state.pages[id: row[0]]?.elaboration == .pending)
    #expect(store.state.pages[id: row[2]]?.elaboration == .pending)
  }

  @Test func swipingOnMidSentence_shouldStopThatPageAndStartTheNext() async {
    let store = makeStore(opening: row[0], writer: HangingInsightWriter())
    store.exhaustivity = .off

    await store.send(.appeared)
    await store.receive(\.pages[id: row[0]].elaborationUpdated)
    #expect(store.state.pages[id: row[0]]?.elaboration == .writing("Half"))

    await store.send(.binding(.set(\.selection, row[1])))
    await store.receive(\.pages[id: row[0]].stop)
    await store.receive(\.pages[id: row[1]].task)
    await store.receive(\.pages[id: row[1]].elaborationUpdated)

    // The page left starts over when the reader comes back; the one on show is writing.
    #expect(store.state.pages[id: row[0]]?.elaboration == .pending)
    #expect(store.state.pages[id: row[1]]?.elaboration == .writing("Half"))

    await store.send(.disappeared)
    await store.receive(\.pages[id: row[1]].stop)
    #expect(store.state.pages[id: row[1]]?.elaboration == .pending)
  }

  @Test func comingBackToAWrittenPage_shouldNotWriteItAgain() async {
    let store = makeStore(opening: row[0], writer: MockCardInsightWriter(snapshots: ["Bloomburrow"]))
    store.exhaustivity = .off
    await store.send(.appeared)
    await store.skipReceivedActions()
    await store.send(.binding(.set(\.selection, row[1])))
    await store.skipReceivedActions()

    store.exhaustivity = .on
    await store.send(.binding(.set(\.selection, row[0]))) {
      $0.selection = row[0]
    }
    // The written page is asked to start and, being written, does nothing.
    await store.receive(\.pages[id: row[0]].task)
    #expect(store.state.pages[id: row[0]]?.elaboration == .written("Bloomburrow"))
  }
}
