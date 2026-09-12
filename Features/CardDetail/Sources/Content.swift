import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit
import SwiftUI

/// The parts of a card detail screen that are settled the moment it opens: its
/// card, and the labels around it.
///
/// Everything that *arrives later* — the prints, the token and combo lists, the
/// set icon, the price history — deliberately lives on `CardDetailFeature.State`
/// instead. `CardDetailView.body` reads this whole struct, so anything stored
/// here invalidates the entire screen when it changes, and these all load
/// asynchronously and often while the reader is mid-scroll. Kept apart, each
/// one re-renders only the section that shows it.
public struct Content: Equatable, Sendable {
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
  let purchaseLabel: String
  let purchaseSubtitleLabel: String
  let priceHistoryLabel: String
  let priceHistorySourceLabel: String
  let priceHistoryUnavailableLabel: String
  let usdLabel: String
  let usdFoilLabel: String
  let usdEtchedLabel: String
  let artistSelectionLabel: String
  let rulingSelectionLabel: String
  let relatedSelectionLabel: String
  let artistSelectionIcon: Image
  let rulingSelectionIcon: Image
  let relatedSelectionIcon: Image
  let queryType: QueryType
  
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
    purchaseLabel = String(localized: "Where to Buy")
    purchaseSubtitleLabel = String(localized: "Live prices from Scryfall")
    priceHistoryLabel = String(localized: "Price History")
    // Attribution only. The line under the title now carries the price move,
    // which is the thing a reader actually looks at a price chart to learn.
    priceHistorySourceLabel = String(localized: "TCGplayer · MTGJSON")
    priceHistoryUnavailableLabel = String(localized: "No price history for this printing")
    usdLabel = String(localized: "Regular")
    usdFoilLabel = String(localized: "Foil")
    usdEtchedLabel = String(localized: "Etched Foil")
    artistSelectionLabel = String(localized: "Artist")
    rulingSelectionLabel = String(localized: "Rulings")
    relatedSelectionLabel = String(localized: "Related")
    artistSelectionIcon = Image(asset: DesignComponentsAsset.artist)
    rulingSelectionIcon = Image(systemName: "text.book.closed.fill")
    relatedSelectionIcon = Image(systemName: "ellipsis.circle")
    
  }
  
  /// Starting values for the sections that load in. They belong to the card
  /// rather than to the screen, so they are derived here and held by the state.
  static func initialSetIconURL(queryType: QueryType) -> URL? {
    switch queryType {
    case .search: nil
    case let .querySet(value, _): URL(string: value.iconSvgUri)
    }
  }

  static func initialVariants(card: Card) -> Content.SubContent {
    SubContent(
      page: 1,
      state: .initial(card),
      title: String(localized: "Prints"),
      subtitleSuffix: String(localized: "Results")
    )
  }

  static var initialRelatedTokens: Content.SubContent {
    SubContent(
      state: .initial(nil),
      title: String(localized: "Tokens"),
      subtitleSuffix: String(localized: "Results")
    )
  }

  static var initialRelatedComboPieces: Content.SubContent {
    SubContent(
      state: .initial(nil),
      title: String(localized: "Combo Pieces"),
      subtitleSuffix: String(localized: "Results")
    )
  }

  static var initialRelatedMeldPieces: Content.SubContent {
    SubContent(
      state: .initial(nil),
      title: String(localized: "Meld Pieces"),
      subtitleSuffix: String(localized: "Results")
    )
  }

  static var initialRelatedMeldResult: Content.SubContent {
    SubContent(
      state: .initial(nil),
      title: String(localized: "Meld Result"),
      subtitleSuffix: String(localized: "Results")
    )
  }

  func getColorIdentity() -> [String] {
    let identity = card.colorIdentity.map { "{\($0.rawValue)}" }
    return identity.isEmpty ? ["{C}"] : identity
  }
  
  // The face being shown is no longer part of `Content`, so it is passed in.
  // These read whichever side of a double-faced card is currently up.
  func getPower(faceDirection: MagicCardFaceDirection?) -> String? {
    card.getCardFace(for: faceDirection)?.power ?? card.power
  }

  func getToughtness(faceDirection: MagicCardFaceDirection?) -> String? {
    card.getCardFace(for: faceDirection)?.toughness ?? card.toughness
  }

  func getLoyalty(faceDirection: MagicCardFaceDirection?) -> String? {
    card.getCardFace(for: faceDirection)?.loyalty ?? card.loyalty
  }

  func getArtistName(faceDirection: MagicCardFaceDirection?) -> String? {
    card.getCardFace(for: faceDirection)?.artist ?? card.artist
  }

  func getDescriptions(faceDirection: MagicCardFaceDirection? = nil) -> [Description] {
    func makeDescription(faceDirection: MagicCardFaceDirection?, card: Card) -> Description {
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
      makeDescription(faceDirection: faceDirection, card: card)
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
        return value.cardDetails.isEmpty ? nil : value
        
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
      self.page = page
      self.state = state
      return self
    }
  }
}
