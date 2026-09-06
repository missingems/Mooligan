import ComposableArchitecture
import Foundation

@Reducer
public struct BulkSyncFeature: Sendable {
  @ObservableState
  public struct State: Equatable {
    public var phase: BulkSyncPhase
    public var lastOutcome: BulkSyncOutcome?

    public init(phase: BulkSyncPhase = .idle, lastOutcome: BulkSyncOutcome? = nil) {
      self.phase = phase
      self.lastOutcome = lastOutcome
    }

    public var hasCompleteCatalog: Bool {
      if case .complete = phase { return true }
      return false
    }
  }

  public enum Action: Equatable, Sendable {
    case registerBackgroundTask
    case task
    case syncRequested(force: Bool)
    case syncFinished(BulkSyncOutcome)
    case phaseChanged(BulkSyncPhase)
    case backgroundTaskFired(BulkSyncTrigger)
    case backgroundTaskFinished(id: UUID, success: Bool)
  }

  private enum CancelID: Hashable {
    case observe
    case sync
  }

  @Dependency(\.bulkDataSyncManager) private var syncManager
  @Dependency(\.bulkSyncScheduler) private var scheduler

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .registerBackgroundTask:
        scheduler.registerBackgroundTask()
        return .none

      case .task:
        return .merge(
          .run { send in
            for await phase in await syncManager.phases() {
              await send(.phaseChanged(phase))
            }
          },
          .run { send in
            for await trigger in scheduler.triggers() {
              await send(.backgroundTaskFired(trigger))
            }
          },
          .send(.syncRequested(force: false))
        )
        .cancellable(id: CancelID.observe)

      case let .syncRequested(force):
        return .run { send in
          await send(.syncFinished(await syncManager.sync(force: force)))
        }
        .cancellable(id: CancelID.sync, cancelInFlight: true)

      case let .syncFinished(outcome):
        state.lastOutcome = outcome
        return .run { [scheduler] _ in
          await scheduler.scheduleNextRun()
        }

      case let .phaseChanged(phase):
        state.phase = phase
        return .none

      case let .backgroundTaskFired(trigger):
        return .run { send in
          let outcome = await syncManager.sync(force: false)
          await send(.syncFinished(outcome))
          await send(.backgroundTaskFinished(id: trigger.id, success: outcome.isSuccess))
        }

      case let .backgroundTaskFinished(id, success):
        return .run { [scheduler] _ in
          scheduler.complete(id, success: success)
        }
      }
    }
  }
}

public extension BulkSyncOutcome {
  var isSuccess: Bool {
    if case .failed = self { return false }
    return true
  }
}
