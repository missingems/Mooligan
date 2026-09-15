import Foundation
import Networking
import ScryfallKit

public extension RulingFeature {
  enum Action: Equatable, Sendable {
    case dismissTapped
    case fetchRulings
    case updateRulings([MagicCardRuling])
  }
}
