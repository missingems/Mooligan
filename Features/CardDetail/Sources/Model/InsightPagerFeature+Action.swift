import ComposableArchitecture
import Foundation

extension InsightPagerFeature {
  @CasePathable enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case pages(IdentifiedActionOf<InformationInsightFeature>)
    case appeared
    case disappeared
  }
}
