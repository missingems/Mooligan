import ComposableArchitecture
import Foundation

extension InformationInsightFeature {
  @CasePathable enum Action: Equatable, Sendable {
    case task
    /// The page was left. Writing that has not finished stops, and starts over on the way back.
    case stop
    case elaborationUpdated(String)
    case elaborationEnded
  }
}
