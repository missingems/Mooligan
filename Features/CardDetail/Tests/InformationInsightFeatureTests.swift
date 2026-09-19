@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct InformationInsightFeatureTests {
  private func makeStore(writer: any CardInsightWriter) -> TestStoreOf<InformationInsightFeature> {
    TestStore(
      initialState: InformationInsightFeature.State(
        widget: .collectorNumber("100"),
        card: Card.mock(name: "Maha, Its Feathers Night", collectorNumber: "100"),
        faceDirection: nil
      )
    ) {
      InformationInsightFeature()
    } withDependencies: {
      $0.cardInsightWriter = writer
    }
  }

  @Test func withoutAppleIntelligence_shouldLeaveTheExplanationOut() async {
    let store = makeStore(writer: MockCardInsightWriter(snapshots: nil))

    await store.send(.task) { state in
      state.elaboration = .unavailable
    }
  }

  @Test func whileTheModelWrites_shouldShowEachSnapshotAndThenTheWholeText() async {
    let store = makeStore(writer: MockCardInsightWriter(snapshots: ["Collector", "Collector number 100 "]))

    await store.send(.task) { state in
      state.elaboration = .writing("")
    }
    await store.receive(.elaborationUpdated("Collector")) { state in
      state.elaboration = .writing("Collector")
    }
    await store.receive(.elaborationUpdated("Collector number 100 ")) { state in
      state.elaboration = .writing("Collector number 100 ")
    }
    await store.receive(.elaborationEnded) { state in
      state.elaboration = .written("Collector number 100")
    }
  }

  @Test func whenTheModelWritesNothing_shouldLeaveTheExplanationOut() async {
    let store = makeStore(writer: MockCardInsightWriter(snapshots: []))

    await store.send(.task) { state in
      state.elaboration = .writing("")
    }
    await store.receive(.elaborationEnded) { state in
      state.elaboration = .unavailable
    }
  }

  @Test func whenTheModelStopsPartWay_shouldKeepWhatItWrote() async {
    let store = makeStore(writer: StoppingInsightWriter(snapshots: ["Collectors tell printings apart"]))

    await store.send(.task) { state in
      state.elaboration = .writing("")
    }
    await store.receive(.elaborationUpdated("Collectors tell printings apart")) { state in
      state.elaboration = .writing("Collectors tell printings apart")
    }
    await store.receive(.elaborationEnded) { state in
      state.elaboration = .written("Collectors tell printings apart")
    }
  }

  @Test func stoppedMidSentence_shouldStartOverNextTime() async {
    let store = makeStore(writer: HangingInsightWriter())

    await store.send(.task) { state in
      state.elaboration = .writing("")
    }
    await store.receive(.elaborationUpdated("Half")) { state in
      state.elaboration = .writing("Half")
    }
    await store.send(.stop) { state in
      state.elaboration = .pending
    }
  }

  @Test func stoppingAWrittenPage_shouldKeepWhatItWrote() async {
    let store = makeStore(writer: MockCardInsightWriter(snapshots: ["Done"]))
    store.exhaustivity = .off
    await store.send(.task)
    await store.finish()
    await store.skipReceivedActions()

    store.exhaustivity = .on
    await store.send(.stop)
    #expect(store.state.elaboration == .written("Done"))
  }

  @Test func onceWritten_shouldNotWriteAgainWhenShownAgain() async {
    let store = makeStore(writer: MockCardInsightWriter())
    store.exhaustivity = .off
    await store.send(.task)
    await store.finish()
    await store.skipReceivedActions()

    store.exhaustivity = .on
    await store.send(.task)
  }
}
