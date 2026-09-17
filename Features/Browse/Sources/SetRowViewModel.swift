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
    let shouldShowIndentIndicator: Bool
    let numberOfCardsLabel: String
    let shouldSetBackground: Bool
    let title: String
    let isFirst: Bool
    let isLast: Bool

    init(
      set: MTGSet,
      isFirst: Bool,
      isLast: Bool,
      index: Int
    ) {
      childIndicatorImageName = "arrow.turn.down.right"
      disclosureIndicatorImageName = "chevron.right"
      iconUrl = URL(string: set.iconSvgUri)
      id = set.code.uppercased()
      shouldShowIndentIndicator = set.parentSetCode != nil
      numberOfCardsLabel = String(localized: "\(set.cardCount) Cards")
      shouldSetBackground = index.isMultiple(of: 2)
      title = set.name
      self.isFirst = isFirst
      self.isLast = isLast
    }

    /// A model for every set of every section, keyed by section. Built once when the sections
    /// land: formatting the card count goes through a number formatter, which is too slow to do
    /// again for each visible row every time the list updates.
    static func rows(in sections: [ScryfallClient.SetsSection]) -> [ScryfallClient.SetsSection.ID: [ViewModel]] {
      Dictionary(uniqueKeysWithValues: sections.map { ($0.id, rows(in: $0.sets)) })
    }

    /// A set with no parent opens a group of rounded corners, and the group closes on the set
    /// before the next parentless one.
    static func rows(in sets: [MTGSet]) -> [ViewModel] {
      sets.indices.map { index in
        let set = sets[index]
        let isLast = sets[safe: index + 1].map { $0.parentSetCode == nil } ?? true
        return ViewModel(
          set: set,
          isFirst: set.parentSetCode == nil || sets[safe: index - 1] == nil,
          isLast: isLast,
          index: index
        )
      }
    }
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
