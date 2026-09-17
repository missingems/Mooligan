import ComposableArchitecture
import Networking
import SwiftUI

extension CardPagerFeature {
  @CasePathable
  public enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case cards(IdentifiedActionOf<CardDetailFeature>)
    case showRulings(PresentationAction<RulingFeature.Action>)
  }
}
