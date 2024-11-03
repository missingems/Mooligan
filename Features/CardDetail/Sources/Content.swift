import DesignComponents
import Networking
import Foundation
import SwiftUI

struct Content<Card: MagicCard>: Equatable, Sendable {
  struct Description: Equatable, Identifiable, Sendable {
    let id = UUID()
    let name: String?
    let text: String?
    let typeline: String?
    let flavorText: String?
    let manaCost: [String]
  }
  
  enum FaceDirection: Equatable {
    case front
    case back
  }
  
  let id: String?
  let collectorNumber: String
  let descriptions: [Description]
  let manaValue: Double?
  let imageURL: URL?
  let power: String?
  let toughness: String?
  let loyalty: String?
  let artist: String?
  let colorIdentity: [String]
  let usdPrice: String?
  let usdFoilPrice: String?
  let tixPrice: String?
  let name: String
  let isLandscape: Bool
  let illstrautedLabel: String
  let infoLabel: String
  let viewRulingsLabel: String
  let legalityLabel: String
  let displayReleasedDate: String
  let variantLabel: String
  let priceLabel: String
  let priceSubtitleLabel: String
  let usdLabel: String
  let usdFoilLabel: String
  let tixLabel: String
  let artistSelectionLabel: String
  let artistSelectionIcon: Image
  let rulingSelectionLabel: String
  let rulingSelectionIcon: Image
  let relatedSelectionLabel: String
  let relatedSelectionIcon: Image
  let rarity: MagicCardRarityValue
  let faceDirection: MagicCardFaceDirection
  
  var numberOfVariantsLabel: String {
    String(localized: "\((try? variants.get().count) ?? 0) Results")
  }
  
  let setCode: String
  var setIconURL: Result<URL?, FeatureError>
  var variants: Result<[Card], FeatureError>
  let card: Card
  let legalities: [MagicCardLegalitiesValue]
  
  init(
    card: Card,
    setIconURL: URL?,
    faceDirection: MagicCardFaceDirection = .front
  ) {
    self.faceDirection = faceDirection
    self.card = card
    id = card.getOracleText()
    name = card.getDisplayName(faceDirection: faceDirection)
    
    usdPrice = card.getPrices().usd
    usdFoilPrice = card.getPrices().usdFoil
    tixPrice = card.getPrices().tix
    manaValue = card.getManaValue()
    isLandscape = card.isSplit
    let identity = card.getColorIdentity().map { "{\($0.value.rawValue)}" }
    colorIdentity = identity.isEmpty ? ["{C}"] : identity
    
    let face = card.getCardFace(for: faceDirection)
    imageURL = face.getImageURL() ?? card.getImageURL()
    
    var descriptions = card.isSplit ? [
      Self.makeDescription(faceDirection: .front, card: card),
      Self.makeDescription(faceDirection: .back, card: card)
    ] : [
      Self.makeDescription(faceDirection: faceDirection, card: card)
    ]
    
    if card.getLayout().value == .adventure {
      descriptions = descriptions.reversed()
    }
    
    self.descriptions = descriptions
    
    power = face.power
    toughness = face.toughness
    loyalty = face.loyalty
    artist = face.artist
    displayReleasedDate = String(localized: "Release Date: \(card.getReleasedAt())")
    
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
    artistSelectionIcon = Image(asset: DesignComponentsAsset.artist)
    rulingSelectionLabel = String(localized: "Rulings")
    rulingSelectionIcon = Image(systemName: "text.book.closed.fill")
    relatedSelectionLabel = String(localized: "Related")
    relatedSelectionIcon = Image(systemName: "ellipsis.circle")
    
    setCode = card.getSet()
    collectorNumber = card.getCollectorNumber()
    legalities = card.getLegalities().value
    self.setIconURL = .success(setIconURL)
    self.variants = .success([card])
    self.rarity = card.getRarity().value
  }
  
  static func makeDescription(faceDirection: MagicCardFaceDirection, card: Card) -> Description {
    Description(
      name: card.getDisplayName(faceDirection: faceDirection),
      text: card.getDisplayText(faceDirection: faceDirection),
      typeline: card.getDisplayTypeline(faceDirection: faceDirection),
      flavorText: card.getCardFace(for: faceDirection).flavorText,
      manaCost: card.getDisplayManaCost(faceDirection: faceDirection)
    )
  }
}
