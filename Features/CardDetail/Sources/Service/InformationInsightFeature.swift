import ComposableArchitecture
import Foundation

/// The explanation of one tile of the information row: one page of `InsightPagerFeature`.
@Reducer struct InformationInsightFeature: Sendable {
  enum CancelID {
    case writing
  }

  @Dependency(\.cardInsightWriter) private var writer

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard state.elaboration == .pending else { return .none }
        guard writer.isAvailable else {
          state.elaboration = .unavailable
          return .none
        }

        state.elaboration = .writing("")
        return .run { [prompt = state.prompt, writer] send in
          do {
            for try await text in writer.write(prompt) {
              await send(.elaborationUpdated(text))
            }
          } catch {
            // The model declined, or stopped part-way. Whatever it wrote before that still stands.
          }
          await send(.elaborationEnded)
        }
        .cancellable(id: CancelID.writing, cancelInFlight: true)

      case .stop:
        guard case .writing = state.elaboration else { return .none }
        state.elaboration = .pending
        return .cancel(id: CancelID.writing)

      case let .elaborationUpdated(text):
        state.elaboration = .writing(text)
        return .none

      case .elaborationEnded:
        guard case let .writing(written) = state.elaboration else { return .none }
        let text = written.trimmingCharacters(in: .whitespacesAndNewlines)
        state.elaboration = text.isEmpty ? .unavailable : .written(text)
        return .none
      }
    }
  }
}
