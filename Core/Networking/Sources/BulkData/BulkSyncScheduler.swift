import ComposableArchitecture
import Foundation

#if os(iOS)
import BackgroundTasks
#endif

public struct BulkSyncTrigger: Sendable, Identifiable, Equatable {
  public let id: UUID

  public init(id: UUID = UUID()) {
    self.id = id
  }
}

public protocol BulkSyncScheduling: Sendable {
  func registerBackgroundTask()

  func triggers() -> AsyncStream<BulkSyncTrigger>

  func complete(_ id: UUID, success: Bool)

  func scheduleNextRun() async
}

public enum BulkSyncSchedulerKey: DependencyKey {
  public static let liveValue: any BulkSyncScheduling = BackgroundTaskBulkSyncScheduler()
#if DEBUG
  public static let previewValue: any BulkSyncScheduling = InertBulkSyncScheduler()
  public static let testValue: any BulkSyncScheduling = InertBulkSyncScheduler()
#endif
}

public extension DependencyValues {
  var bulkSyncScheduler: any BulkSyncScheduling {
    get { self[BulkSyncSchedulerKey.self] }
    set { self[BulkSyncSchedulerKey.self] = newValue }
  }
}

#if DEBUG
public struct InertBulkSyncScheduler: BulkSyncScheduling {
  public init() {}
  public func registerBackgroundTask() {}
  public func complete(_ id: UUID, success: Bool) {}
  public func scheduleNextRun() async {}

  public func triggers() -> AsyncStream<BulkSyncTrigger> {
    AsyncStream { $0.finish() }
  }
}
#endif

public final class BackgroundTaskBulkSyncScheduler: BulkSyncScheduling, @unchecked Sendable {
  public static let taskIdentifier = "com.missingems.mooligan.bulkSync"

  private let lock = NSLock()
  private var continuations: [UUID: AsyncStream<BulkSyncTrigger>.Continuation] = [:]

#if os(iOS)
  private var pendingTasks: [UUID: BGTask] = [:]
#endif

  public init() {}

  public func triggers() -> AsyncStream<BulkSyncTrigger> {
    let key = UUID()
    let (stream, continuation) = AsyncStream<BulkSyncTrigger>.makeStream()

    lock.withLock { continuations[key] = continuation }
    continuation.onTermination = { [weak self] _ in
      guard let self else { return }
      lock.withLock { _ = continuations.removeValue(forKey: key) }
    }

    return stream
  }

  private func fire() -> BulkSyncTrigger {
    let trigger = BulkSyncTrigger()
    let observers = lock.withLock { Array(continuations.values) }

    for observer in observers {
      observer.yield(trigger)
    }

    return trigger
  }

#if os(iOS)
  public func registerBackgroundTask() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: Self.taskIdentifier,
      using: .main
    ) { task in
      let trigger = self.fire()
      self.lock.withLock { self.pendingTasks[trigger.id] = task }

      task.expirationHandler = {
        self.complete(trigger.id, success: false)
      }
    }
  }

  public func complete(_ id: UUID, success: Bool) {
    let task = lock.withLock { pendingTasks.removeValue(forKey: id) }
    task?.setTaskCompleted(success: success)
  }

  public func scheduleNextRun() async {
    let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = true
    request.earliestBeginDate = BulkRefreshSchedule.nextDailyBoundary(after: Date())

    do {
      try await BGTaskScheduler.shared.submitTaskRequest(request)
    } catch {
      bulkSyncLogger.debug("could not schedule bulk sync: \(error.localizedDescription)")
    }
  }
#else
  public func registerBackgroundTask() {}
  public func complete(_ id: UUID, success: Bool) {}
  public func scheduleNextRun() async {}
#endif
}
