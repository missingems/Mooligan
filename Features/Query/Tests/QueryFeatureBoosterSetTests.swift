@testable import Query
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct QueryFeatureBoosterSetTests {
  private var searchQuery: SearchQuery {
    SearchQuery(page: 1, sortMode: .name, sortDirection: .auto)
  }

  /// A set only sells boosters once it has come out, so every read pins the date it is made on.
  private func boosterSet(for queryType: QueryType, on now: Date) -> MTGSet? {
    withDependencies {
      $0.date.now = now
    } operation: {
      QueryFeature.State(mode: .placeholder, queryType: queryType).boosterSet
    }
  }

  @Test func whenShowingASearch_shouldHaveNoBoosterSet() {
    // 1 January 2026, after every mock set's release.
    #expect(boosterSet(for: .search(searchQuery), on: Date(timeIntervalSince1970: 1_767_225_600)) == nil)
  }

  @Test func whenTheSetWasNeverSoldInPacks_shouldHaveNoBoosterSet() {
    // The Final Fantasy mock is filed as an Alchemy set, which only ever existed online.
    let set = MockGameSetRequestClient.mockSets[0]

    #expect(boosterSet(for: .querySet(set, searchQuery), on: Date(timeIntervalSince1970: 1_767_225_600)) == nil)
  }

  @Test func whenTheSetSellsBoosters_shouldOfferThatSet() {
    // Tarkir: Dragonstorm, a paper expansion released on 11 April 2025.
    let set = MockGameSetRequestClient.mockSets[1]

    let offered = boosterSet(for: .querySet(set, searchQuery), on: Date(timeIntervalSince1970: 1_767_225_600))

    #expect(offered == set)
    // What the pack button's menu lists for it.
    #expect(offered?.stockedPackKinds == [BoosterPackKind.play, .collector])
  }

  @Test func whenTheSetHasNotComeOutYet_shouldHaveNoBoosterSet() {
    let set = MockGameSetRequestClient.mockSets[1]

    // 1 January 2025, three months before Tarkir: Dragonstorm's release.
    #expect(boosterSet(for: .querySet(set, searchQuery), on: Date(timeIntervalSince1970: 1_735_689_600)) == nil)
  }
}
