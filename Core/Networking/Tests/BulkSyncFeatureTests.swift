@testable import Networking
import ComposableArchitecture
import Foundation
import Testing

@MainActor struct BulkSyncFeatureTests {
  private final class StubSyncManager: BulkDataSyncManaging, @unchecked Sendable {
    private let lock = NSLock()
    private var _outcome: BulkSyncOutcome
    private var _forcedCalls: [Bool] = []

    init(outcome: BulkSyncOutcome = .upToDate) {
      _outcome = outcome
    }

    var forcedCalls: [Bool] { lock.withLock { _forcedCalls } }

    func setOutcome(_ outcome: BulkSyncOutcome) {
      lock.withLock { _outcome = outcome }
    }

    func sync(force: Bool) async -> BulkSyncOutcome {
      lock.withLock {
        _forcedCalls.append(force)
        return _outcome
      }
    }

    func phase() async -> BulkSyncPhase { .idle }

    func phases() async -> AsyncStream<BulkSyncPhase> {
      AsyncStream { $0.finish() }
    }
  }

  private final class SpyScheduler: BulkSyncScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var _completed: [(id: UUID, success: Bool)] = []
    private var _scheduledRuns = 0
    private var _registered = false

    var completed: [(id: UUID, success: Bool)] { lock.withLock { _completed } }
    var scheduledRuns: Int { lock.withLock { _scheduledRuns } }
    var didRegister: Bool { lock.withLock { _registered } }

    func registerBackgroundTask() { lock.withLock { _registered = true } }
    func triggers() -> AsyncStream<BulkSyncTrigger> { AsyncStream { $0.finish() } }
    func complete(_ id: UUID, success: Bool) { lock.withLock { _completed.append((id, success)) } }
    func scheduleNextRun() { lock.withLock { _scheduledRuns += 1 } }
  }

  private func makeStore(
    manager: StubSyncManager,
    scheduler: SpyScheduler
  ) -> TestStoreOf<BulkSyncFeature> {
    TestStore(initialState: BulkSyncFeature.State()) {
      BulkSyncFeature()
    } withDependencies: {
      $0.bulkDataSyncManager = manager
      $0.bulkSyncScheduler = scheduler
    }
  }

  @Test func whenTheAppLaunches_shouldRegisterTheBackgroundTask() async {
    let scheduler = SpyScheduler()
    let store = makeStore(manager: StubSyncManager(), scheduler: scheduler)

    await store.send(.registerBackgroundTask)

    #expect(scheduler.didRegister)
  }

  @Test func whenTheAppAppears_shouldRunASyncWithoutForcingIt() async {
    let manager = StubSyncManager(outcome: .upToDate)
    let scheduler = SpyScheduler()
    let store = makeStore(manager: manager, scheduler: scheduler)

    await store.send(.task)
    await store.receive(.syncRequested(force: false))
    await store.receive(.syncFinished(.upToDate)) { state in
      state.lastOutcome = .upToDate
    }

    #expect(manager.forcedCalls == [false])
    await store.finish()
  }

  @Test func whenASyncFinishes_shouldAskForTheNextBackgroundRun() async {
    let manager = StubSyncManager(outcome: .downloadQueued)
    let scheduler = SpyScheduler()
    let store = makeStore(manager: manager, scheduler: scheduler)

    await store.send(.syncRequested(force: false))
    await store.receive(.syncFinished(.downloadQueued)) { state in
      state.lastOutcome = .downloadQueued
    }
    await store.finish()

    #expect(scheduler.scheduledRuns == 1)
  }

  @Test func whenPhasePublished_shouldMirrorItIntoState() async {
    let store = makeStore(manager: StubSyncManager(), scheduler: SpyScheduler())

    await store.send(.phaseChanged(.ingesting(cards: 4_000))) { state in
      state.phase = .ingesting(cards: 4_000)
    }

    #expect(store.state.hasCompleteCatalog == false)
  }

  @Test func whenIngestCompletes_shouldReportACompleteCatalog() async {
    let store = makeStore(manager: StubSyncManager(), scheduler: SpyScheduler())

    await store.send(.phaseChanged(.complete(cards: 116_129))) { state in
      state.phase = .complete(cards: 116_129)
    }

    #expect(store.state.hasCompleteCatalog)
  }

  @Test func whenABackgroundTaskFires_shouldSyncThenTellTheSystemItIsDone() async {
    let manager = StubSyncManager(outcome: .ingested(cards: 10))
    let scheduler = SpyScheduler()
    let store = makeStore(manager: manager, scheduler: scheduler)
    let trigger = BulkSyncTrigger()

    await store.send(.backgroundTaskFired(trigger))
    await store.receive(.syncFinished(.ingested(cards: 10))) { state in
      state.lastOutcome = .ingested(cards: 10)
    }
    await store.receive(.backgroundTaskFinished(id: trigger.id, success: true))
    await store.finish()

    #expect(scheduler.completed.map(\.id) == [trigger.id])
    #expect(scheduler.completed.map(\.success) == [true])
  }

  @Test func whenABackgroundSyncFails_shouldReportFailureToTheSystem() async {
    let manager = StubSyncManager(outcome: .failed("offline"))
    let scheduler = SpyScheduler()
    let store = makeStore(manager: manager, scheduler: scheduler)
    let trigger = BulkSyncTrigger()

    await store.send(.backgroundTaskFired(trigger))
    await store.receive(.syncFinished(.failed("offline"))) { state in
      state.lastOutcome = .failed("offline")
    }
    await store.receive(.backgroundTaskFinished(id: trigger.id, success: false))
    await store.finish()

    #expect(scheduler.completed.map(\.success) == [false])
  }

  @Test func whenRefreshIsRequestedExplicitly_shouldForceTheSync() async {
    let manager = StubSyncManager(outcome: .ingested(cards: 3))
    let store = makeStore(manager: manager, scheduler: SpyScheduler())

    await store.send(.syncRequested(force: true))
    await store.receive(.syncFinished(.ingested(cards: 3))) { state in
      state.lastOutcome = .ingested(cards: 3)
    }
    await store.finish()

    #expect(manager.forcedCalls == [true])
  }

  @Test func outcomesOtherThanFailureShouldCountAsSuccess() {
    #expect(BulkSyncOutcome.upToDate.isSuccess)
    #expect(BulkSyncOutcome.skippedNotDue.isSuccess)
    #expect(BulkSyncOutcome.downloadQueued.isSuccess)
    #expect(BulkSyncOutcome.ingested(cards: 1).isSuccess)
    #expect(BulkSyncOutcome.failed("nope").isSuccess == false)
  }
}
