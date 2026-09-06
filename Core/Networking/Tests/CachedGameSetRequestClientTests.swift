@testable import Networking
import Dependencies
import Foundation
import ScryfallKit
import SQLiteData
import Testing

struct CachedGameSetRequestClientTests {
  private struct Harness {
    let client: CachedGameSetRequestClient
    let remote: SpyGameSetRequestClient
    let store: CardStore
    let clock: TestClock
  }

  private func makeHarness() throws -> Harness {
    let database = try makeTestDatabase()
    let remote = SpyGameSetRequestClient()
    let clock = TestClock()

    let (client, store) = withDependencies {
      $0.context = .test
      $0.defaultDatabase = database
      $0.date = .init { clock.now }
      $0.remoteGameSetRequestClient = remote
    } operation: {
      (CachedGameSetRequestClient(), CardStore())
    }

    return Harness(client: client, remote: remote, store: store, clock: clock)
  }

  @Test func whenNothingIsCached_shouldFetchOnceAndPersist() async throws {
    let harness = try makeHarness()

    let (sections, sets) = try await harness.client.getSets(queryType: .all)

    #expect(harness.remote.callCount == 1)
    #expect(sections.isEmpty == false)
    #expect(sets.count == MockGameSetRequestClient.mockSets.count)
    #expect(try await harness.store.allSets().count == sets.count)
  }

  @Test func whenCachedAndFresh_shouldNotHitTheNetworkAgain() async throws {
    let harness = try makeHarness()
    _ = try await harness.client.getSets(queryType: .all)

    let (sections, sets) = try await harness.client.getSets(queryType: .all)

    #expect(harness.remote.callCount == 1)
    #expect(sets.isEmpty == false)
    #expect(sections.isEmpty == false)
  }

  @Test func whenCacheIsADayOld_shouldRefreshOnTheNextLaunch() async throws {
    let harness = try makeHarness()
    _ = try await harness.client.getSets(queryType: .all)

    harness.clock.advancePastDailyBoundary()
    _ = try await harness.client.getSets(queryType: .all)

    #expect(harness.remote.callCount == 2)
  }

  @Test func whenRevalidating_shouldAlwaysHitTheNetwork() async throws {
    let harness = try makeHarness()
    _ = try await harness.client.getSets(queryType: .all)

    _ = try await harness.client.getSets(queryType: .all, policy: .revalidate)

    #expect(harness.remote.callCount == 2)
  }

  @Test func whenRefreshingBringsANewSet_shouldPersistIt() async throws {
    let harness = try makeHarness()
    _ = try await harness.client.getSets(queryType: .all)
    let original = MockGameSetRequestClient.mockSets

    var newSet = original[0]
    newSet.id = UUID()
    newSet.code = "new"
    newSet.name = "Brand New Set"
    harness.remote.setSets(original + [newSet])

    let (_, sets) = try await harness.client.getSets(queryType: .all, policy: .revalidate)

    #expect(sets.contains { $0.code == "new" })
    #expect(try await harness.store.allSets().contains { $0.code == "new" })
  }

  @Test func whenOfflineWithACachedList_shouldServeTheCachedList() async throws {
    let harness = try makeHarness()
    _ = try await harness.client.getSets(queryType: .all)

    harness.remote.setError(StubError())
    harness.clock.advancePastDailyBoundary()

    let (sections, sets) = try await harness.client.getSets(queryType: .all)

    #expect(sets.isEmpty == false)
    #expect(sections.isEmpty == false)
  }

  @Test func whenOfflineWithNothingCached_shouldThrow() async throws {
    let harness = try makeHarness()
    harness.remote.setError(StubError())

    await #expect(throws: StubError.self) {
      _ = try await harness.client.getSets(queryType: .all)
    }
  }

  @Test func whenSearchingWithNoLoadedSets_shouldUseTheCache() async throws {
    let harness = try makeHarness()
    _ = try await harness.client.getSets(queryType: .all)

    let (sections, sets) = try await harness.client.getSets(
      queryType: .name("Final Fantasy", [])
    )

    #expect(harness.remote.callCount == 1)
    #expect(sets.isEmpty == false)
    #expect(sections.flatMap(\.sets).contains { $0.name == "Final Fantasy" })
  }

  @Test func whenSearchingWithLoadedSets_shouldNotTouchTheStoreOrNetwork() async throws {
    let harness = try makeHarness()
    let sets = MockGameSetRequestClient.mockSets

    let (sections, returned) = try await harness.client.getSets(
      queryType: .name("Final Fantasy", sets)
    )

    #expect(harness.remote.callCount == 0)
    #expect(returned.count == sets.count)
    #expect(sections.isEmpty == false)
  }

  @Test func whenSectioningCachedSets_shouldMatchTheLiveGrouping() async throws {
    let harness = try makeHarness()
    let expected = ScryfallClient.sections(from: MockGameSetRequestClient.mockSets)

    _ = try await harness.client.getSets(queryType: .all)
    let (sections, _) = try await harness.client.getSets(queryType: .all)

    #expect(sections.map(\.displayDate) == expected.map(\.displayDate))
    #expect(sections.map { $0.sets.map(\.code) } == expected.map { $0.sets.map(\.code) })
  }
}
