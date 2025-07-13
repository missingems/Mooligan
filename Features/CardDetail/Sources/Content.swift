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
  let queryType: QueryType
  var setIconURL: URL?
  var variants: SubContent
  var relatedTokens: SubContent?
  var relatedComboPieces: SubContent?
  var displayableCardImage: DisplayableCardImage
  
  init(
    card: Card,
    queryType: QueryType
  ) {
    self.card = card
    self.queryType = queryType
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
    
    switch queryType {
    case .search:
      setIconURL = nil
      
    case let .querySet(value, _):
      setIconURL = URL(string: value.iconSvgUri)
    }
    
    variants = SubContent(
      page: 1,
      state: .initial(card),
      title: String(localized: "Prints"),
      subtitleSuffix: String(localized: "Results")
    )
    
    relatedTokens = SubContent(
      state: .initial(nil),
      title: String(localized: "Tokens"),
      subtitleSuffix: String(localized: "Results")
    )
    
    relatedComboPieces = SubContent(
      state: .initial(nil),
      title: String(localized: "Combo Pieces"),
      subtitleSuffix: String(localized: "Results")
    )
    
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

extension Content {
  enum State: Equatable {
    case initial(Card?)
    case data(CardDataSource)
    
    var value: CardDataSource? {
      switch self {
      case let .data(value):
        return value
        
      case let .initial(value):
        return if let value {
          CardDataSource(cards: [value], hasNextPage: false, total: 1)
        } else {
          nil
        }
      }
    }
    
    var isInitial: Bool {
      switch self {
      case .initial:
        return true
        
      case .data:
        return false
      }
    }
  }
}

extension Content {
  struct SubContent: Equatable {
    var page: Int
    var state: State
    let title: String
    private let subtitleSuffix: String
    
    var subtitle: String {
      String(localized: "\(state.value?.cardDetails.count ?? 0) \(subtitleSuffix)")
    }
    
    init(page: Int = 1, state: State, title: String, subtitleSuffix: String) {
      self.page = page
      self.state = state
      self.title = title
      self.subtitleSuffix = subtitleSuffix
    }
    
    mutating func updating(page: Int, state: State) -> Self {
      self.state = state
      return self
    }
  }
}
