import Networking
import Foundation

struct Content<Card: MagicCard>: Equatable {
  struct Description: Equatable, Identifiable {
    let id = UUID()
    let name: String?
    let text: String?
    let typeline: String?
    let flavorText: String?
    let manaCost: String?
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
  let isLandscape: Bool
  let illstrautedLabel: String
  let viewRulingsLabel: String
  let legalityLabel: String
  let displayReleasedDate: String
  let setCode: String
  var setIconURL: URL?
  var variants: [Card] = []
  let card: Card
  let legalities: [MagicCardLegalitiesValue]
  
  init(
    card: Card,
    setIconURL: URL?,
    faceDirection: MagicCardFaceDirection = .front
  ) {
    self.card = card
    id = card.getOracleText()
    
    // MARK: - Card Configuration
    usdPrice = card.getPrices().usd
    usdFoilPrice = card.getPrices().usdFoil
    tixPrice = card.getPrices().tix
    manaValue = card.getManaValue()
    isLandscape = card.isSplit
    let identity = card.getColorIdentity().map { "{\($0.value.rawValue)}" }
    colorIdentity = identity.isEmpty ? ["{C}"] : identity
    
    // MARK: - Selected Face Configuration
    let face = card.getCardFace(for: faceDirection)
    imageURL = face.getImageURL()
    
    descriptions = {
      if card.isSplit {
        [
          Self.makeDescription(faceDirection: .front, card: card),
          Self.makeDescription(faceDirection: .back, card: card),
        ]
      } else {
        [Self.makeDescription(faceDirection: faceDirection, card: card)]
      }
    }()
    
    power = face.power
    toughness = face.toughness
    loyalty = face.loyalty
    artist = face.artist
    displayReleasedDate = String(localized: "Release Date: \(card.getReleasedAt())")
    
    // MARK: - Static Labels
    illstrautedLabel = String(localized: "Artist")
    viewRulingsLabel = String(localized: "Rulings")
    legalityLabel = String(localized: "Legality")
    setCode = card.getSet()
    collectorNumber = card.getCollectorNumber()
    legalities = card.getLegalities().value
    self.setIconURL = setIconURL
  }
  
  static func makeDescription(faceDirection: MagicCardFaceDirection, card: Card) -> Description {
    Description(
      name: card.getDisplayName(faceDirection: faceDirection),
      text: card.getDisplayText(faceDirection: faceDirection),
      typeline: card.getDisplayTypeline(faceDirection: faceDirection),
      flavorText: card.getFlavorText(),
      manaCost: card.getDisplayManaCost(faceDirection: faceDirection)
    )
  }
}
