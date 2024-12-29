import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit
import SwiftUI

struct Content: Equatable {
  
  // MARK: - Nested Structs and Enums
  
  struct Description: Equatable, Sendable {
    let name: String
    let textElements: [[TextElement]]
    let typeline: String?
    let flavorText: String?
    let manaCost: [String]
  }
  
  // MARK: - Identifiers
  
  let card: Card
  var selectedMode: CardView.Mode
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
  let rarity: Card.Rarity
  let legalities: [MagicCardLegalitiesValue]
  
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
  var setIconURL: URL?
  var variants: IdentifiedArrayOf<Card>
  
  func artCroppedImageURL(with faceDirection: MagicCardFaceDirection) -> URL? {
    let url: URL?
    
    switch faceDirection {
    case .front:
      url = card.getImageURL(type: .artCrop, getSecondFace: false)
      
    case .back:
      url = card.getImageURL(type: .artCrop, getSecondFace: true)
    }
    
    return url ?? card.getImageURL(type: .artCrop)
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
    
    usdPrice = card.prices.usd
    usdFoilPrice = card.prices.usdFoil
    tixPrice = card.prices.tix
    manaValue = card.cmc
    displayReleasedDate = String(localized: "Release Date: \(card.releasedAt)")
    
    // Initialize Labels
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
    descriptionCallToActionLabel = card.layout.callToActionLabel
    descriptionCallToActionIconName = card.layout.callToActionIconName
    
    // Initialize Icons
    artistSelectionIcon = Image(asset: DesignComponentsAsset.artist)
    rulingSelectionIcon = Image(systemName: "text.book.closed.fill")
    relatedSelectionIcon = Image(systemName: "ellipsis.circle")
    
    setCode = card.set
    collectorNumber = card.collectorNumber
    legalities = card.legalities.all
    self.setIconURL = setIconURL
    self.variants = IdentifiedArrayOf(uniqueElements: [])
    self.rarity = card.rarity
    
    name = card.name(faceDirection: faceDirection)
    
    let identity = card.colorIdentity.map { "{\($0.rawValue)}" }
    colorIdentity = identity.isEmpty ? ["{C}"] : identity
    
    let face = card.getCardFace(for: faceDirection)
    imageURL = face?.imageUris?.normal.map { URL(string: $0)} ?? card.getImageURL(type: .normal)
    
    let descriptions = card.hasMultipleColumns ? [
      Self.makeDescription(faceDirection: .front, card: card),
      Self.makeDescription(faceDirection: .back, card: card)
    ] : [
      Self.makeDescription(faceDirection: faceDirection, card: card)
    ]
    
    if card.layout == .adventure {
      self.descriptions = descriptions.reversed()
    } else {
      self.descriptions = descriptions
    }
    
    power = face?.power
    toughness = face?.toughness
    loyalty = face?.loyalty
    artist = face?.artist
    selectedMode = CardView.Mode(card)
  }
  
  // MARK: - Methods
  
  mutating func populate(with card: Card, faceDirection: MagicCardFaceDirection) {
    name = card.name(faceDirection: faceDirection)
    
    let identity = card.colorIdentity.map { "{\($0.rawValue)}" }
    colorIdentity = identity.isEmpty ? ["{C}"] : identity
    
    let face = card.getCardFace(for: faceDirection)
    imageURL = face?.imageUris?.normal.map { URL(string: $0)} ?? card.getImageURL(type: .normal)
    
    let descriptions = card.hasMultipleColumns ? [
      Self.makeDescription(faceDirection: .front, card: card),
      Self.makeDescription(faceDirection: .back, card: card)
    ] : [
      Self.makeDescription(faceDirection: faceDirection, card: card)
    ]
    
    if card.layout == .adventure {
      self.descriptions = descriptions.reversed()
    } else {
      self.descriptions = descriptions
    }
    
    power = face?.power
    toughness = face?.toughness
    loyalty = face?.loyalty
    artist = face?.artist
  }
  
  static func makeDescription(faceDirection: MagicCardFaceDirection, card: Card) -> Description {
    Description(
      name: card.name(faceDirection: faceDirection),
      textElements: card.text(faceDirection: faceDirection),
      typeline: card.typeline(faceDirection: faceDirection),
      flavorText: card.flavorText(faceDirection: faceDirection),
      manaCost: card.manaCost(faceDirection: faceDirection)
    )
  }
}
