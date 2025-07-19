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
          attributedTitle[attributedRange].backgroundColor = .yellow
          attributedTitle[attributedRange].font = .body.bold()
        }
        
        self.attributedTitle = attributedTitle
      } else {
        attributedTitle = AttributedString(set.name)
      }
      
      self.isFirst = set.parentSetCode == nil
      self.isLast = isLast
    }
  }
}

extension Array where Element == MTGSet {
  func mappedToSetRowViewModels(
    highlightedText: String?
  ) -> [SetRow.ViewModel] {
    let zipped = zip(self, self.indices)
    var data: [SetRow.ViewModel] = []
    for value in zipped {
      let set = value.0
      let index = value.1
      let nextIndex = index
      let isLast: Bool
      
      if let nextSet = self[safe: nextIndex] {
        if nextSet.parentSetCode != nil {
          isLast = true
        } else {
          isLast = false
        }
      } else {
        isLast = true
      }
      
      let viewModel = SetRow.ViewModel(
        set: set,
        selectedSet: nil,
        highlightedText: highlightedText,
        isLast: isLast,
        index: index
      )
      data.append(viewModel)
    }
    
    return data
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

