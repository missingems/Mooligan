@testable import Networking
import Dependencies
import Foundation
import ScryfallKit
import SQLiteData
import Testing

struct BulkDataSyncManagerTests {
  private let downloadURL = URL(
    string: "https://data.scryfall.io/default-cards/default-cards-1.jsonl.gz"
  )!

  private struct Harness {
    let manager: BulkDataSyncManager
    let client: StubBulkDataRequestClient
    let downloader: StubBulkDataDownloader
    let store: CardStore
    let clock: TestClock
  }

  private func makeHarness(updatedAt: String = "2026-09-05T21:05:33Z") throws -> Harness {
    let database = try makeTestDatabase()
    let client = StubBulkDataRequestClient(
      items: [BulkFixture.item(updatedAt: updatedAt, downloadURI: downloadURL.absoluteString)]
    )
    let downloader = StubBulkDataDownloader()
    let clock = TestClock()

    let (manager, store) = withDependencies {
      $0.context = .test
      $0.defaultDatabase = database
      $0.date = .init { clock.now }
      $0.bulkDataRequestClient = client
      $0.bulkDataDownloader = downloader
    } operation: {
      (BulkDataSyncManager(), CardStore())
    }

    return Harness(
      manager: manager, client: client, downloader: downloader, store: store, clock: clock
    )
  }

  @Test func whenNothingHasBeenDownloaded_shouldQueueTheTransferAndReturn() async throws {
    let harness = try makeHarness()

    let outcome = await harness.manager.sync()

    #expect(outcome == .downloadQueued)
    #expect(await harness.downloader.enqueuedURLs == [downloadURL])

    let state = try #require(try await harness.store.syncState(id: BulkDataItem.defaultCardsType))
    #expect(state.syncStatus == .downloading)
    #expect(state.hasCompleteCatalog == false)
  }

  @Test func whenADownloadFinishedWhileAway_shouldIngestItOnTheNextRun() async throws {
    let harness = try makeHarness()
    let cards = CardFixtures.set(code: "fdn", count: 5)
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: cards), for: downloadURL
    )

    let outcome = await harness.manager.sync()

    #expect(outcome == .ingested(cards: 5))
    #expect(try await harness.store.cardCount(inSet: "fdn") == 5)
    #expect(await harness.downloader.discardedURLs == [downloadURL])
  }

  @Test func whenIngestSucceeds_shouldMarkTheCatalogComplete() async throws {
    let harness = try makeHarness(updatedAt: "2026-09-05T21:05:33Z")
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 3)),
      for: downloadURL
    )

    await harness.manager.sync()

    let state = try #require(try await harness.store.syncState(id: BulkDataItem.defaultCardsType))
    #expect(state.hasCompleteCatalog)
    #expect(state.ingestedCardCount == 3)
    #expect(state.remoteUpdatedAt == "2026-09-05T21:05:33Z")
  }

  @Test func whenCheckedRecently_shouldNotCallTheAPIAgain() async throws {
    let harness = try makeHarness()
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 2)),
      for: downloadURL
    )

    await harness.manager.sync()
    #expect(harness.client.callCount == 1)

    harness.clock.advance(by: 60 * 60)
    let outcome = await harness.manager.sync()

    #expect(outcome == .skippedNotDue)
    #expect(harness.client.callCount == 1)
  }

  @Test func whenForced_shouldCheckEvenIfNotDue() async throws {
    let harness = try makeHarness()
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 2)),
      for: downloadURL
    )

    await harness.manager.sync()
    harness.clock.advance(by: 60)

    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 4)),
      for: downloadURL
    )
    let outcome = await harness.manager.sync(force: true)

    #expect(outcome == .ingested(cards: 4))
    #expect(harness.client.callCount == 2)
  }

  @Test func whenADayHasPassedAndNothingChanged_shouldReportUpToDate() async throws {
    let harness = try makeHarness(updatedAt: "2026-09-05T21:05:33Z")
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 2)),
      for: downloadURL
    )
    await harness.manager.sync()

    harness.clock.advancePastDailyBoundary()
    let outcome = await harness.manager.sync()

    #expect(outcome == .upToDate)
    #expect(harness.client.callCount == 2)
  }

  @Test func whenANewerFileExistsButTheCatalogIsFresh_shouldNotReingest() async throws {
    let harness = try makeHarness(updatedAt: "2026-09-05T21:05:33Z")
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 2)),
      for: downloadURL
    )
    await harness.manager.sync()

    harness.clock.advancePastDailyBoundary()
    harness.client.setItems([
      BulkFixture.item(updatedAt: "2026-09-06T21:05:33Z", downloadURI: downloadURL.absoluteString)
    ])
    let outcome = await harness.manager.sync()

    #expect(outcome == .upToDate)
  }

  @Test func whenANewerFileExistsAndTheCatalogIsStale_shouldReingest() async throws {
    let harness = try makeHarness(updatedAt: "2026-09-05T21:05:33Z")
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 2)),
      for: downloadURL
    )
    await harness.manager.sync()

    harness.clock.advancePastWeeklyBoundary()
    harness.client.setItems([
      BulkFixture.item(updatedAt: "2026-09-20T21:05:33Z", downloadURI: downloadURL.absoluteString)
    ])
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 6)),
      for: downloadURL
    )
    let outcome = await harness.manager.sync()

    #expect(outcome == .ingested(cards: 6))
    #expect(try await harness.store.cardCount(inSet: "fdn") == 6)
  }

  @Test func whenAPrintingLeavesTheExport_shouldRemoveItButKeepAPIFetchedCards() async throws {
    let harness = try makeHarness(updatedAt: "2026-09-05T21:05:33Z")
    let retained = CardFixtures.card(name: "Still Printed", collectorNumber: "1")
    let withdrawn = CardFixtures.card(name: "Withdrawn", collectorNumber: "2")
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: [retained, withdrawn]), for: downloadURL
    )
    await harness.manager.sync()

    let apiOnly = CardFixtures.card(name: "Fetched Directly", collectorNumber: "9")
    try await harness.store.upsert(cards: [apiOnly], source: .api)

    harness.clock.advancePastWeeklyBoundary()
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: [retained]), for: downloadURL
    )
    await harness.manager.sync(force: true)

    #expect(try await harness.store.card(id: retained.id) != nil)
    #expect(try await harness.store.card(id: withdrawn.id) == nil)
    #expect(try await harness.store.card(id: apiOnly.id) != nil)
  }

  @Test func whenANewBuildIsSeenLongBeforeTheRefreshIsDue_shouldStillReingestLater() async throws {
    let harness = try makeHarness(updatedAt: "2026-09-05T21:05:33Z")
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 2)),
      for: downloadURL
    )
    await harness.manager.sync()

    harness.client.setItems([
      BulkFixture.item(updatedAt: "2026-09-06T21:05:33Z", downloadURI: downloadURL.absoluteString)
    ])

    harness.clock.advancePastDailyBoundary()
    #expect(await harness.manager.sync() == .upToDate)

    for _ in 2...7 {
      harness.clock.advancePastDailyBoundary()
      _ = await harness.manager.sync()
    }

    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 5)),
      for: downloadURL
    )

    harness.clock.advancePastDailyBoundary()
    #expect(await harness.manager.sync() == .ingested(cards: 5))
  }

  @Test func whenTheFileHasNonPaperPrintings_shouldNotStoreThem() async throws {
    let harness = try makeHarness()
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(
        cards: [
          CardFixtures.card(name: "Paper", collectorNumber: "1"),
          CardFixtures.card(name: "Arena", collectorNumber: "2", games: [.arena]),
          CardFixtures.card(name: "MTGO", collectorNumber: "3", games: [.mtgo]),
        ]
      ),
      for: downloadURL
    )

    let outcome = await harness.manager.sync()

    #expect(outcome == .ingested(cards: 1))
    #expect(try await harness.store.cardCount(inSet: "fdn") == 1)
  }

  @Test func whenALineIsMalformed_shouldIngestTheRest() async throws {
    let harness = try makeHarness()
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(
        cards: CardFixtures.set(code: "fdn", count: 3),
        extraLines: ["{ this is not json", "{\"object\":\"card\"}"]
      ),
      for: downloadURL
    )

    let outcome = await harness.manager.sync()

    #expect(outcome == .ingested(cards: 3))
  }

  @Test func whenTheFileExceedsOneBatch_shouldIngestEveryCard() async throws {
    let harness = try makeHarness()
    let count = BulkDataSyncManager.batchSize + 250
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: count)),
      for: downloadURL
    )

    let outcome = await harness.manager.sync()

    #expect(outcome == .ingested(cards: count))
    #expect(try await harness.store.cardCount(inSet: "fdn") == count)
  }

  @Test func whenReingesting_shouldUpdateExistingRowsRatherThanDuplicate() async throws {
    let harness = try makeHarness(updatedAt: "2026-09-05T21:05:33Z")
    let ids = (0..<3).map { _ in UUID() }
    let original = ids.enumerated().map {
      CardFixtures.card(id: $0.element, name: "Old \($0.offset)", collectorNumber: "\($0.offset)")
    }
    try await harness.downloader.stage(try BulkFixture.gzippedJSONL(cards: original), for: downloadURL)
    await harness.manager.sync()

    let updated = ids.enumerated().map {
      CardFixtures.card(id: $0.element, name: "New \($0.offset)", collectorNumber: "\($0.offset)")
    }
    try await harness.downloader.stage(try BulkFixture.gzippedJSONL(cards: updated), for: downloadURL)
    await harness.manager.sync(force: true)

    #expect(try await harness.store.cardCount(inSet: "fdn") == 3)
    #expect(try await harness.store.card(id: ids[0])?.name == "New 0")
  }

  @Test func whenTheStagedFileIsNotGzip_shouldFailWithoutClaimingACatalog() async throws {
    let harness = try makeHarness()
    try await harness.downloader.stage(Data("<!doctype html><html>nope".utf8), for: downloadURL)

    let outcome = await harness.manager.sync()

    guard case .failed = outcome else {
      Issue.record("expected a failure, got \(outcome)")
      return
    }

    let state = try #require(try await harness.store.syncState(id: BulkDataItem.defaultCardsType))
    #expect(state.syncStatus == .failed)
    #expect(state.hasCompleteCatalog == false)
  }

  @Test func whenTheCatalogueRequestFails_shouldReportFailure() async throws {
    let harness = try makeHarness()
    harness.client.setError(BulkDataRequestClientError.badStatus(503))

    let outcome = await harness.manager.sync()

    guard case .failed = outcome else {
      Issue.record("expected a failure, got \(outcome)")
      return
    }
  }

  @Test func whenScryfallStopsOfferingTheType_shouldReportFailure() async throws {
    let harness = try makeHarness()
    harness.client.setItems([])

    let outcome = await harness.manager.sync()

    guard case .failed = outcome else {
      Issue.record("expected a failure, got \(outcome)")
      return
    }
  }

  @Test func whenIngesting_shouldPublishPhasesEndingInComplete() async throws {
    let harness = try makeHarness()
    try await harness.downloader.stage(
      try BulkFixture.gzippedJSONL(cards: CardFixtures.set(code: "fdn", count: 4)),
      for: downloadURL
    )

    await harness.manager.sync()

    #expect(await harness.manager.phase() == .complete(cards: 4))
  }
}
