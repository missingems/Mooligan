import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit
import SwiftUI

public struct Content: Equatable {
  struct Description: Equatable, Sendable {
    let name: String
    let textElements: [[TextElement]]
    let typeline: String?
    let flavorText: String?
    let manaCost: [String]
  }
  
  let card: Card
  let illstrautedLabel: String
  let infoLabel: String
  let viewRulingsLabel: String
  let legalityLabel: String
  let variantLabel: String
  let priceLabel: String
  let priceSubtitleLabel: String
  let usdLabel: String
  let usdFoilLabel: String
  let tixLabel: String
  let artistSelectionLabel: String
  let rulingSelectionLabel: String
  let relatedSelectionLabel: String
  let artistSelectionIcon: Image
  let rulingSelectionIcon: Image
  let relatedSelectionIcon: Image
  
  var numberOfVariantsLabel: String {
    String(localized: "\(variants.total) Results")
  }
  
  var setIconURL: URL?
  var variants: CardDataSource
  var variantsQueryPage: Int = 1
  var displayableCardImage: DisplayableCardImage
  
  init(
    card: Card,
    setIconURL: URL?
  ) {
    self.card = card
    
    illstrautedLabel = String(localized: "Artist")
    viewRulingsLabel = String(localized: "Rulings")
    legalityLabel = String(localized: "Legality")
    infoLabel = String(localized: "Information")
    variantLabel = String(localized: "Prints")
    priceLabel = String(localized: "Market Prices")
    priceSubtitleLabel = String(localized: "Data from Scryfall")
    usdLabel = String(localized: "USD")
    usdFoilLabel = String(localized: "USD - Foil")
    tixLabel = String(localized: "Tix")
    artistSelectionLabel = String(localized: "Artist")
    rulingSelectionLabel = String(localized: "Rulings")
    relatedSelectionLabel = String(localized: "Related")
    artistSelectionIcon = Image(asset: DesignComponentsAsset.artist)
    rulingSelectionIcon = Image(systemName: "text.book.closed.fill")
    relatedSelectionIcon = Image(systemName: "ellipsis.circle")
    
    self.setIconURL = setIconURL
    variants = CardDataSource(cards: [], focusedCard: nil, hasNextPage: false, total: 1)
    displayableCardImage = DisplayableCardImage(card)
  }
  
  func getColorIdentity() -> [String] {
    let identity = card.colorIdentity.map { "{\($0.rawValue)}" }
    return identity.isEmpty ? ["{C}"] : identity
  }
  
  func getPower() -> String? {
    let face = card.getCardFace(for: displayableCardImage.faceDirection)
    return face?.power ?? card.power
  }
  
  func getToughtness() -> String? {
    let face = card.getCardFace(for: displayableCardImage.faceDirection)
    return face?.toughness ?? card.toughness
  }
  
  func getLoyalty() -> String? {
    let face = card.getCardFace(for: displayableCardImage.faceDirection)
    return face?.loyalty ?? card.loyalty
  }
  
  func getArtistName() -> String? {
    let face = card.getCardFace(for: displayableCardImage.faceDirection)
    return face?.artist ?? card.artist
  }
  
  func getDescriptions() -> [Description] {
    func makeDescription(faceDirection: MagicCardFaceDirection, card: Card) -> Description {
      Description(
        name: card.name(faceDirection: faceDirection),
        textElements: card.text(faceDirection: faceDirection),
        typeline: card.typeline(faceDirection: faceDirection),
        flavorText: card.flavorText(faceDirection: faceDirection),
        manaCost: card.manaCost(faceDirection: faceDirection)
      )
    }
    
    return card.hasMultipleColumns ? [
      makeDescription(faceDirection: .front, card: card),
      makeDescription(faceDirection: .back, card: card)
    ] : [
      makeDescription(faceDirection: displayableCardImage.faceDirection, card: card)
    ]
  }
}
