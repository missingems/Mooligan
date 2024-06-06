import Networking
import Foundation

struct Content<Card: MagicCard>: Equatable {
  enum FaceDirection: Equatable {
    case front
    case back
  }
  
  let id: String?
  let name: String?
  let text: String?
  let typeline: String?
  let flavorText: String?
  let manaValue: Double?
  let imageURL: URL?
  let power: String?
  let toughness: String?
  let loyalty: String?
  let artist: String?
  let colorIdentity: [String]
  let manaCost: [String]
  let usdPrice: String?
  let usdFoilPrice: String?
  let tixPrice: String?
  let isLandscape: Bool
  let illstrautedLabel: String
  let viewRulingsLabel: String
  let legalityLabel: String
  let displayReleasedDate: String
  let card: Card
  var variants: [Card] = []
  
  init(card: Card, faceDirection: MagicCardFaceDirection = .front) {
    self.card = card
    id = card.getOracleText()
    manaCost = []
    
    // MARK: - Card Configuration
    usdPrice = card.getPrices().usd
    usdFoilPrice = card.getPrices().usdFoil
    tixPrice = card.getPrices().tix
    manaValue = card.getManaValue()
    isLandscape = card.isLandscape
    colorIdentity = {
      let identity = card.getColorIdentity().map { "{\($0.value.rawValue)}" }
      if identity.isEmpty {
        return ["{C}"]
      } else {
        return identity
      }
    }()
    
    // MARK: - Selected Face Configuration
    let face = card.getCardFace(for: faceDirection)
    imageURL = face.getImageURL()
    
    if card.isPhyrexian {
      name = face.name
      text = face.oracleText
      typeline = face.typeLine
    } else {
      name = face.printedName ?? face.name
      text = face.printedText ?? face.oracleText
      typeline = face.printedTypeLine ?? face.typeLine
    }
    
    power = face.power
    toughness = face.toughness
    flavorText = face.flavorText
    loyalty = face.loyalty
    artist = face.artist
    displayReleasedDate = String(localized: "Release Date: \(card.getReleasedAt())")
    
    // MARK: - Static Labels
    illstrautedLabel = String(localized: "Artist")
    viewRulingsLabel = String(localized: "Rulings")
    legalityLabel = String(localized: "Legality")
  }
}
