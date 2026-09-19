import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit

public extension CardDetailFeature {
  @ObservableState struct State: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var content: Content
    var priceHistory: PriceHistoryDisplay
    var pullOdds: PullOddsStatus = .loading
    public var setIconURL: URL?
    var variants: Content.SubContent
    var relatedTokens: Content.SubContent?
    var relatedComboPieces: Content.SubContent?
    var relatedMeldPieces: Content.SubContent?
    var relatedMeldResult: Content.SubContent?
    public var displayableCardImage: DisplayableCardImage?
    
    public init(card: Card, displayableCardImage: DisplayableCardImage? = nil, queryType: QueryType) {
      self.id = card.id
      let content = Content(card: card, queryType: queryType)
      self.content = content
      self.priceHistory = .loading(card: card, labels: content.priceHistoryLabels)
      
      setIconURL = Content.initialSetIconURL(queryType: queryType)
      variants = Content.initialVariants(card: card)
      relatedTokens = Content.initialRelatedTokens
      relatedComboPieces = Content.initialRelatedComboPieces
      relatedMeldPieces = Content.initialRelatedMeldPieces
      relatedMeldResult = Content.initialRelatedMeldResult
      self.displayableCardImage = displayableCardImage ?? DisplayableCardImage(card)
    }
  }
}
