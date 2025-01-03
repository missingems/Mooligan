@testable import Browse
import ComposableArchitecture
import Foundation
import Networking
import Testing
import ScryfallKit

struct BrowseFeatureTests {
  private let mockSet = MTGSet(
    id: UUID(),
    code: "123",
    mtgoCode: "123",
    tcgplayerId: 1,
    name: "Testing",
    setType: .alchemy,
    releasedAt: "19-10-1992",
    blockCode: "123",
    block: "123",
    parentSetCode: "123",
    cardCount: 100,
    printedSize: 100,
    digital: false,
    foilOnly: false,
    nonfoilOnly: false,
    scryfallUri: "scryfallUri",
    uri: "uri",
    iconSvgUri: "iconSvgUri",
    searchUri: "searchUri"
  )
  
  @Test func whenViewAppeared_shouldFetchSets_thenUpdateSets() async {
    let store: TestStoreOf<Browse.Feature> = await TestStore(initialState: Browse.Feature.State(selectedSet: nil, sets: [])) {
      Browse.Feature()
    }
    
    // When
    await store.send(.viewAppeared)
    
    // Should
    await store.receive(.fetchSets, timeout: 1)
    
    // Then
    await store.receive(.updateSets(MockGameSetRequestClient.mockSets)) { state in
      state.sets = .init(uniqueElements: MockGameSetRequestClient.mockSets)
    }
  }
  
  @Test func whenDidSelectSet_shouldUpdateSelectedSet() async {
    let sets = MockGameSetRequestClient.mockSets
    let store: TestStoreOf<Browse.Feature> = await TestStore(initialState: Browse.Feature.State(selectedSet: nil, sets: .init(uniqueElements: sets))) {
      Browse.Feature()
    }
    
    // When
    await store.send(.didSelectSet(sets[1])) { state in
      // Should
      state.selectedSet = sets[1]
    }
  }
  
  @Test func defaultState() async {
    let store: TestStoreOf<Browse.Feature> = await TestStore(initialState: Browse.Feature.State(selectedSet: nil, sets: [])) {
      Browse.Feature()
    }
    
    #expect(await store.state.sets.isEmpty == true)
    #expect(await store.state.selectedSet == nil)
  }
}
