import ComposableArchitecture
import DesignComponents
import Foundation
import Networking

extension CardDetailFeature.State {
  mutating func updateAdditionalInformation(_ information: CardDetailFeature.AdditionalInformation) {
    updateSetIconURL(information.setIconURL)
    updateVariants(information.variants, page: 1)
    updateRelatedTokens(information.relatedTokens)
    updateComboPieces(information.relatedComboPieces)
    updateMeldPieces(information.relatedMeldPieces)
    updateMeldResult(information.relatedMeldResult)
  }

  mutating func updateSetIconURL(_ url: URL?) {
    if let url { setIconURL = url }
  }
  
  mutating func updateVariants(_ dataSource: CardDataSource, page: Int) {
    variants = variants.updating(page: page, state: .data(dataSource))
  }

  mutating func updatePriceHistory(_ display: PriceHistoryDisplay) {
    priceHistory = display
  }
  mutating func updateRelatedTokens(_ dataSource: CardDataSource) {
    relatedTokens = relatedTokens?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func updateComboPieces(_ dataSource: CardDataSource) {
    relatedComboPieces = relatedComboPieces?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func updateMeldPieces(_ dataSource: CardDataSource) {
    relatedMeldPieces = relatedMeldPieces?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func updateMeldResult(_ dataSource: CardDataSource) {
    relatedMeldResult = relatedMeldResult?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func toggleCardImageDescription() {
    switch displayableCardImage {
    case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName, id):
      displayableCardImage = .transformable(
        direction: direction.toggled(), frontImageURL: frontImageURL,
        backImageURL: backImageURL, callToActionIconName: callToActionIconName, id: id
      )
      
    case let .flippable(direction, displayingImageURL, callToActionIconName, id):
      displayableCardImage = .flippable(
        direction: direction.toggled(), displayingImageURL: displayingImageURL,
        callToActionIconName: callToActionIconName, id: id
      )
      
    case .single, nil:
      // Only a card with two faces shows the call to action, so there is nothing to turn over.
      reportIssue("descriptionCallToActionTapped isn't available to single face card.")
    }
  }
}
