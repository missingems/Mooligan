import Dependencies
import Foundation

public extension DependencyValues {
  var cardPullOddsSource: any CardPullOddsSource {
    get { self[CardPullOddsSourceKey.self] }
    set { self[CardPullOddsSourceKey.self] = newValue }
  }
}
