import Foundation
import ScryfallKit

public struct MockMagicCard<
    Face: MagicCardFace,
    Color: MagicCardColor,
    Layout: MagicCardLayout,
    Legalities: MagicCardLegalities,
    Prices: MagicCardPrices,
    Rarity: MagicCardRarity
>: MagicCard {
  public var id = UUID()
  private var language: String
  private var cardFace: Face
  private var manaValue: Double?
  private var colorIdentity: [Color]
  private var colorIndicator: [Color]?
  private var colors: [Color]?
  private var keywords: [String]
  private var layout: Layout
  private var legalities: Legalities
  private var loyalty: String?
  private var name: String
  private var oracleText: String?
  private var power: String?
  private var producedMana: [Color]?
  private var toughness: String?
  private var typeline: String?
  private var artist: String?
  private var collectorNumber: String
  private var flavorText: String?
  private var prices: Prices
  private var printedName: String?
  private var printedText: String?
  private var printedTypeLine: String?
  private var purchaseUris: [String: String]?
  private var rarity: Rarity
  private var relatedUris: [String: String]
  private var releastedAt: String
  private var setName: String
  private var set: String
  private var imageURL: URL?
  
  public func getLanguage() -> String { language }
  public func getCardFace(for direction: MagicCardFaceDirection) -> any MagicCardFace { cardFace }
  public func getManaValue() -> Double? { manaValue }
  public func getColorIdentity() -> [any MagicCardColor] { colorIdentity }
  public func getColorIndicator() -> [any MagicCardColor]? { colorIndicator }
  public func getColors() -> [any MagicCardColor]? { colors }
  public func getKeywords() -> [String] { keywords }
  public func getLayout() -> any MagicCardLayout { layout }
  public func getLegalities() -> any MagicCardLegalities { legalities }
  public func getLoyalty() -> String? { loyalty }
  public func getName() -> String { name }
  public func getOracleText() -> String? { oracleText }
  public func getPower() -> String? { power }
  public func getProducedMana() -> [any MagicCardColor]? { producedMana }
  public func getToughness() -> String? { toughness }
  public func getTypeLine() -> String? { typeline }
  public func getArtist() -> String? { artist }
  public func getCollectorNumber() -> String { collectorNumber }
  public func getFlavorText() -> String? { flavorText }
  public func getPrices() -> any MagicCardPrices { prices }
  public func getPrintedName() -> String? { printedName }
  public func getPrintedText() -> String? { printedText }
  public func getPrintedTypeLine() -> String? { printedTypeLine }
  public func getPurchaseUris() -> [String: String]? { purchaseUris }
  public func getRarity() -> any MagicCardRarity { rarity }
  public func getRelatedUris() -> [String: String] { relatedUris }
  public func getReleasedAt() -> String { releastedAt }
  public func getSetName() -> String { setName }
  public func getSet() -> String { set }
  public func getImageURL() -> URL? { imageURL }
}
