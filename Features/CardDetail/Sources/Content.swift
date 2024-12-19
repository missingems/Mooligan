import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import SwiftUI

struct Content<Card: MagicCard>: Equatable {
  
  // MARK: - Nested Structs and Enums
  
  struct Description: Equatable, Sendable {
    let name: String
    let text: String?
    let typeline: String?
    let flavorText: String?
    let manaCost: [String]
  }
  
  // MARK: - Identifiers
  
  let card: Card
  var selectedMode: CardView<Card>.Mode?
  let setCode: String
  let collectorNumber: String
  var faceDirection: MagicCardFaceDirection {
    didSet {
      populate(with: card, faceDirection: faceDirection)
    }
  }
  
  // MARK: - Card Attributes
  
  var descriptions: [Description]
  var manaValue: Double?
  var power: String?
  var toughness: String?
  var loyalty: String?
  var artist: String?
  var colorIdentity: [String]
  let rarity: MagicCardRarityValue
  let legalities: [MagicCardLegalitiesValue]
  let keywords: [String]
  
  // MARK: - Prices
  
  let usdPrice: String?
  let usdFoilPrice: String?
  let tixPrice: String?
  
  // MARK: - Display Attributes
  
  var name: String
  let displayReleasedDate: String
  
  // MARK: - Labels
  
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
  let descriptionCallToActionLabel: String?
  let descriptionCallToActionIconName: String?
  
  var numberOfVariantsLabel: String {
    String(localized: "\(variants.count) Results")
  }
  
  // MARK: - Images
  
  var imageURL: URL?
  var setIconURL: Result<URL?, FeatureError>
  var variants: IdentifiedArrayOf<Card>
  
  func artCroppedImageURL(with faceDirection: MagicCardFaceDirection) -> URL? {
    let url: URL?
    
    switch faceDirection {
    case .front:
      url = card.getCardFace(for: faceDirection).getArtCroppedImageURL()
      
    case .back:
      url = card.getCardFace(for: faceDirection).getArtCroppedImageURL()
    }
    
    return url ?? card.getArtCroppedImageURL()
  }
  
  // MARK: - Icons
  
  let artistSelectionIcon: Image
  let rulingSelectionIcon: Image
  let relatedSelectionIcon: Image
  
  // MARK: - Initializer
  
  init(
    card: Card,
    setIconURL: URL?,
    faceDirection: MagicCardFaceDirection = .front
  ) {
    self.faceDirection = faceDirection
    self.card = card
    
    usdPrice = card.getPrices().usd
    usdFoilPrice = card.getPrices().usdFoil
    tixPrice = card.getPrices().tix
    manaValue = card.getManaValue()
    displayReleasedDate = String(localized: "Release Date: \(card.getReleasedAt())")
    
    // Initialize Labels
    illstrautedLabel = String(localized: "Artist")
    viewRulingsLabel = String(localized: "Rulings")
    legalityLabel = String(localized: "Legality")
    infoLabel = String(localized: "Information")
    variantLabel = String(localized: "Prints")
    priceLabel = String(localized: "Market Prices")
    priceSubtitleLabel = String(localized: "Data from Scryfall")
    usdLabel = String(localized: "USD")
    usdFoilLabel = String(localized: "USD")
    tixLabel = String(localized: "Tix")
    artistSelectionLabel = String(localized: "Artist")
    rulingSelectionLabel = String(localized: "Rulings")
    relatedSelectionLabel = String(localized: "Related")
    descriptionCallToActionLabel = card.getLayout().value.callToActionLabel
    descriptionCallToActionIconName = card.getLayout().value.callToActionIconName
    
    // Initialize Icons
    artistSelectionIcon = Image(asset: DesignComponentsAsset.artist)
    rulingSelectionIcon = Image(systemName: "text.book.closed.fill")
    relatedSelectionIcon = Image(systemName: "ellipsis.circle")
    
    setCode = card.getSet()
    collectorNumber = card.getCollectorNumber()
    legalities = card.getLegalities().value
    self.setIconURL = .success(setIconURL)
    self.variants = IdentifiedArrayOf(uniqueElements: [])
    self.rarity = card.getRarity().value
    
    name = card.getDisplayName(faceDirection: faceDirection)
    
    let identity = card.getColorIdentity().map { "{\($0.value.rawValue)}" }
    colorIdentity = identity.isEmpty ? ["{C}"] : identity
    
    let face = card.getCardFace(for: faceDirection)
    imageURL = face.getImageURL() ?? card.getImageURL()
    
    var descriptions = card.hasMultipleColumns ? [
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
    keywords = card.getKeywords()
    selectedMode = CardView<Card>.Mode(card)
  }
  
  // MARK: - Methods
  
  mutating func populate(with card: Card, faceDirection: MagicCardFaceDirection) {
    name = card.getDisplayName(faceDirection: faceDirection)
    
    let identity = card.getColorIdentity().map { "{\($0.value.rawValue)}" }
    colorIdentity = identity.isEmpty ? ["{C}"] : identity
    
    let face = card.getCardFace(for: faceDirection)
    imageURL = card.getImageURL()
    
    var descriptions = card.hasMultipleColumns ? [
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
