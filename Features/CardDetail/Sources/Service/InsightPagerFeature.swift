import ComposableArchitecture
import Foundation

/// Every tile of the information row explained, a page each, swiped between under a carousel of
/// their badges.
///
/// Runs in a store of its own rather than one scoped from the card's. The explanations are written a
/// few words at a time, and every word is a state change: scoped from the card, each one would
/// re-render the whole card page under the overlay, since a store read registers on its whole state.
///
/// Only the page on show writes. Each starts when it is landed on, and one left before it finished
/// stops, so the on-device model answers one request at a time however fast the reader swipes.
@Reducer struct InsightPagerFeature: Sendable {
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .appeared:
        guard let selection = state.selection else { return .none }
        return .send(.pages(.element(id: selection, action: .task)))

      case .disappeared:
        return stopWriting(except: nil, in: state)

      case .binding(\.selection):
        guard let selection = state.selection else { return stopWriting(except: nil, in: state) }
        return .merge(
          stopWriting(except: selection, in: state),
          .send(.pages(.element(id: selection, action: .task)))
        )

      case .binding, .pages:
        return .none
      }
    }
    .forEach(\.pages, action: \.pages) {
      InformationInsightFeature()
    }
  }

  private func stopWriting(except page: InformationWidget?, in state: State) -> Effect<Action> {
    .merge(
      state.pages
        .filter { $0.id != page && $0.elaboration.isWriting }
        .map { .send(.pages(.element(id: $0.id, action: .stop))) }
    )
  }
}
