@testable import Browse
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct BrowseFeatureTests {
  private var sections: [ScryfallClient.SetsSection] {
    MockGameSetRequestClient.mocksSetSections
  }

  private var sets: [MTGSet] {
    MockGameSetRequestClient.mockSets
  }

  private func makeStore() -> TestStoreOf<BrowseFeature> {
    TestStore(initialState: BrowseFeature.State()) {
      BrowseFeature()
    }
  }

  @Test func whenInitialised_shouldStartWithPlaceholders() {
    let state = BrowseFeature.State()

    #expect(state.sets.isEmpty)
    #expect(state.selectedSet == nil)
    #expect(state.query.isEmpty)
    #expect(state.mode.isPlaceholder)
  }

  @Test func whenInitialisedWithASelectedSet_shouldKeepIt() {
    let state = BrowseFeature.State(selectedSet: sets[0])

    #expect(state.selectedSet == sets[0])
  }

  @Test func whenViewAppeared_shouldSearchSets_thenUpdateSections() async {
    let store = makeStore()

    // When
    await store.send(.viewAppeared)

    // Should
    await store.receive(.searchSets(.all))

    // Then
    await store.receive(.updateSetSections(sections: sections, flattened: sets)) { state in
      state.sets = self.sets
      state.mode = .data(IdentifiedArrayOf(uniqueElements: self.sections))
    }
  }

  @Test func whenViewAppearedWithLoadedData_shouldNotSearchAgain() async {
    let store = makeStore()

    // Given
    await store.send(.updateSetSections(sections: sections, flattened: sets)) { state in
      state.sets = self.sets
      state.mode = .data(IdentifiedArrayOf(uniqueElements: self.sections))
    }

    // When / Then no further search is made.
    await store.send(.viewAppeared)
  }

  @Test func whenDidSelectSet_shouldUpdateSelectedSet() async {
    let store = makeStore()

    await store.send(.didSelectSet(sets[1])) { state in
      state.selectedSet = self.sets[1]
    }
  }

  @Test func whenFetchFails_shouldEnterErrorMode() async {
    let store = makeStore()

    await store.send(.fetchFailed("Offline")) { state in
      state.mode = .error("Offline")
    }
  }

  @Test func whenRetrying_shouldShowPlaceholders_thenSearchAgain() async {
    let store = makeStore()

    // Given
    await store.send(.fetchFailed("Offline")) { state in
      state.mode = .error("Offline")
    }

    // When
    await store.send(.retry) { state in
      state.mode = .placeholder(
        IdentifiedArrayOf(uniqueElements: MockGameSetRequestClient.mocksSetSections)
      )
    }

    // Should
    await store.receive(.searchSets(.all))

    // Then
    await store.receive(.updateSetSections(sections: sections, flattened: sets)) { state in
      state.sets = self.sets
      state.mode = .data(IdentifiedArrayOf(uniqueElements: self.sections))
    }
  }

  @Test func whenRetryingWithAQuery_shouldSearchByName() async {
    let clock = TestClock()
    let store = TestStore(initialState: BrowseFeature.State()) {
      BrowseFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }
    store.exhaustivity = .off

    // Given a query has been entered.
    await store.send(.binding(.set(\.query, "Final")))

    // When
    await store.send(.retry)

    // Then the retry searches by name rather than fetching everything.
    await store.receive(.searchSets(.name("Final", [])))

    await clock.advance(by: .milliseconds(300))
    await store.finish()
  }

  @Test func whenQueryChanges_shouldDebounceThenSearchByName() async {
    let clock = TestClock()
    let store = TestStore(initialState: BrowseFeature.State()) {
      BrowseFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }
    store.exhaustivity = .off

    // When
    await store.send(.binding(.set(\.query, "Final"))) { state in
      state.query = "Final"
    }

    // Then nothing is searched until the debounce elapses.
    await clock.advance(by: .milliseconds(299))
    await clock.advance(by: .milliseconds(1))

    await store.receive(.searchSets(.name("Final", [])))
    await store.finish()
  }

  @Test func whenSearching_shouldUpdateSections() async {
    let store = makeStore()

    // When
    await store.send(.searchSets(.all))

    // Then
    await store.receive(.updateSetSections(sections: sections, flattened: sets)) { state in
      state.sets = self.sets
      state.mode = .data(IdentifiedArrayOf(uniqueElements: self.sections))
    }
  }

  @Test func whenSectionsUpdate_shouldLeavePlaceholderMode() async {
    let store = makeStore()

    #expect(store.state.mode.isPlaceholder)

    await store.send(.updateSetSections(sections: sections, flattened: sets)) { state in
      state.sets = self.sets
      state.mode = .data(IdentifiedArrayOf(uniqueElements: self.sections))
    }

    #expect(store.state.mode.isPlaceholder == false)
  }
}
