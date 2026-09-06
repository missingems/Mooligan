@testable import Mooligan
import Browse
import ComposableArchitecture
import Foundation
import Networking
import Testing

@MainActor struct AppFeatureTests {
  private final class SpyDatabasePreparer: DatabasePreparing, @unchecked Sendable {
    private let lock = NSLock()
    private var _prepareCount = 0

    var prepareCount: Int { lock.withLock { _prepareCount } }

    func prepare() {
      lock.withLock { _prepareCount += 1 }
    }
  }

  private final class SpyScheduler: BulkSyncScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var _registered = false

    var didRegister: Bool { lock.withLock { _registered } }

    func registerBackgroundTask() { lock.withLock { _registered = true } }
    func triggers() -> AsyncStream<BulkSyncTrigger> { AsyncStream { $0.finish() } }
    func complete(_ id: UUID, success: Bool) {}
    func scheduleNextRun() {}
  }

  @Test func whenSetUp_shouldPrepareTheCacheThenRegisterTheBackgroundTask() async {
    let preparer = SpyDatabasePreparer()
    let scheduler = SpyScheduler()
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.databasePreparer = preparer
      $0.bulkSyncScheduler = scheduler
    }

    await store.send(.setup)
    await store.receive(\.bulkSync.registerBackgroundTask)

    #expect(preparer.prepareCount == 1)
    #expect(scheduler.didRegister)
  }

  @Test func whenSetUpTwice_shouldNotPrepareTheCacheAgain() async {
    let preparer = SpyDatabasePreparer()
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.databasePreparer = preparer
      $0.bulkSyncScheduler = SpyScheduler()
    }

    await store.send(.setup)
    await store.receive(\.bulkSync.registerBackgroundTask)

    #expect(preparer.prepareCount == 1)
  }

  @Test func whenInitialised_shouldStartOnTheSetsTabWithAnEmptyPath() {
    let state = Feature.State()

    #expect(state.selectedTab == .sets)
    #expect(state.path.isEmpty)
    #expect(state.selectedSet == nil)
    #expect(state.bulkSync.phase == .idle)
  }

  @Test func whenASetIsSelected_shouldPushASetDetailPage() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.databasePreparer = SpyDatabasePreparer()
      $0.bulkSyncScheduler = SpyScheduler()
    }
    store.exhaustivity = .off

    let set = MockGameSetRequestClient.mockSets[0]
    await store.send(.sets(.didSelectSet(set)))

    #expect(store.state.selectedSet == set)
    #expect(store.state.path.count == 1)
  }
}
