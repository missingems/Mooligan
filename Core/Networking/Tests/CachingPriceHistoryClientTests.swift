@testable import Networking
import Dependencies
import Foundation
import ScryfallKit
import SQLiteData
import Testing

struct CachingPriceHistoryClientTests {
  private final class Build: @unchecked Sendable {
    var version: String? = "5.2.2+20260918"
  }

  private let database: any DatabaseWriter
  private let upstream = SpyPriceHistoryClient()
  private let build = Build()
  private let card = CardFixtures.card()

  init() throws {
    database = try makeTestDatabase()
  }

  /// A fresh client each time, as after a relaunch: only the database carries over.
  private func makeClient() -> CachingPriceHistoryClient {
    withDependencies {
      $0.context = .test
      $0.defaultDatabase = database
      $0.date = .constant(Date(timeIntervalSince1970: 1_790_000_000))
    } operation: {
      CachingPriceHistoryClient(upstream: upstream, build: { [build] in build.version })
    }
  }

  @Test func whenOpenedAgainOnTheSameBuild_shouldReadTheStoredHistory() async throws {
    _ = try await makeClient().history(for: card)
    let again = try await makeClient().history(for: card)

    #expect(upstream.callCount == 1)
    #expect(again.series[.normal]?.first?.amount == 1)
  }

  @Test func whenMTGJSONHasANewBuild_shouldAskTheFeedAgain() async throws {
    _ = try await makeClient().history(for: card)

    build.version = "5.2.2+20260919"
    upstream.setAmount(2)
    let again = try await makeClient().history(for: card)

    #expect(upstream.callCount == 2)
    #expect(again.series[.normal]?.first?.amount == 2)
  }

  @Test func whenTheFeedFails_shouldShowTheLastStoredHistory() async throws {
    _ = try await makeClient().history(for: card)

    build.version = "5.2.2+20260919"
    upstream.setError(PriceHistoryClientError.badStatus(503))
    let again = try await makeClient().history(for: card)

    #expect(upstream.callCount == 2)
    #expect(again.series[.normal]?.first?.amount == 1)
  }

  @Test func whenTheFeedFailsWithNothingStored_shouldThrow() async throws {
    upstream.setError(PriceHistoryClientError.badStatus(503))

    await #expect(throws: PriceHistoryClientError.badStatus(503)) {
      try await makeClient().history(for: card)
    }
  }

  @Test func whenAskingForSeveralSeries_shouldStoreEachUnderItsOwnKey() async throws {
    let requests = [
      PriceSeriesRequest(provider: .tcgplayer, listType: .retail),
      PriceSeriesRequest(provider: .cardkingdom, listType: .buylist),
    ]
    _ = try await makeClient().histories(for: card, requests: requests)
    let again = try await makeClient().histories(for: card, requests: requests)

    #expect(upstream.callCount == 2)
    #expect(again[requests[1]]?.provider == .cardkingdom)
    #expect(again[requests[1]]?.listType == .buylist)
  }
}
