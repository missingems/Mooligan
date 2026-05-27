import Foundation
import Networking
import SwiftUI
import ScryfallKit

extension SetRow {
  struct ViewModel: Equatable {
    let childIndicatorImageName: String
    let disclosureIndicatorImageName: String
    let iconUrl: URL?
    let id: String
    let isSelected: Bool
    let shouldShowIndentIndicator: Bool
    let numberOfCardsLabel: String
    let shouldSetBackground: Bool
    let attributedTitle: AttributedString
    let isFirst: Bool
    let isLast: Bool
    
    init(
      set: MTGSet,
      selectedSet: MTGSet?,
      highlightedText: String? = nil,
      isFirst: Bool,
      isLast: Bool,
      index: Int
    ) {
      childIndicatorImageName = "arrow.turn.down.right"
      disclosureIndicatorImageName = "chevron.right"
      iconUrl = URL(string: set.iconSvgUri)
      id = set.code.uppercased()
      isSelected = selectedSet?.id == set.id
      shouldShowIndentIndicator = set.parentSetCode != nil
      numberOfCardsLabel = String(localized: "\(set.cardCount) Cards")
      shouldSetBackground = index.isMultiple(of: 2)
      
      if let highlight = highlightedText, !highlight.isEmpty {
        var attributedTitle = AttributedString(set.name)
        
        if let attributedRange = attributedTitle.range(of: highlight, options: .caseInsensitive) {
          attributedTitle[attributedRange].backgroundColor = .yellow.opacity(0.8)
          attributedTitle[attributedRange].font = .body.bold()
          attributedTitle[attributedRange].foregroundColor = .black
        }
        
        self.attributedTitle = attributedTitle
      } else {
        attributedTitle = AttributedString(set.name)
      }
      self.isFirst = isFirst
      self.isLast = isLast
    }
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

