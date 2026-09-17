import DesignComponents
import Foundation
import Networking

public extension CardDetailFeature {
  /// Everything a card loads when it appears besides price history, delivered as one action.
  struct AdditionalInformation: Equatable, Sendable {
    var setIconURL: URL?
    var variants: CardDataSource
    var relatedTokens: CardDataSource
    var relatedComboPieces: CardDataSource
    var relatedMeldPieces: CardDataSource
    var relatedMeldResult: CardDataSource
  }
}
