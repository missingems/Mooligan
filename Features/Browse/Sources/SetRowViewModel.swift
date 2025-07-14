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
    
    init(
      set: MTGSet,
      selectedSet: MTGSet?,
      highlightedText: String? = nil,
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
          attributedTitle[attributedRange].backgroundColor = .yellow
          attributedTitle[attributedRange].font = .body.bold()
        }
        
        self.attributedTitle = attributedTitle
      } else {
        attributedTitle = AttributedString(set.name)
      }
    }
  }
}
