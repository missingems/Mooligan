import ComposableArchitecture
import Foundation
import Networking

/// Settings. For now only its Developer section, which shows when each dataset the app downloads
/// was last brought up to date. It is in every build, TestFlight's and the App Store's included,
/// so a report of stale data can be checked against it on the device it happened on.
@Reducer
public struct SettingsFeature {
  @ObservableState
  public struct State: Equatable {
    var freshness: DataFreshness?
  }

  public enum Action {
    case task
    case refresh
    case freshnessLoaded(DataFreshness)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task, .refresh:
        return .run { send in
          if let freshness = try? await DataFreshnessReader().read() {
            await send(.freshnessLoaded(freshness))
          }
        }

      case let .freshnessLoaded(freshness):
        state.freshness = freshness
        return .none
      }
    }
  }
}
