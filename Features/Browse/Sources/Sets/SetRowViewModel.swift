import Foundation
import Networking
import SwiftUI

extension SetRow {
  struct ViewModel: Equatable {
    let colorScheme: ColorScheme
    let childIndicatorImageName: String
    let disclosureIndicatorImageName: String
    let iconUrl: URL?
    let id: String
    let isSelected: Bool
    let shouldShowIndentIndicator: Bool
    let numberOfCardsLabel: String
    let shouldSetBackground: Bool
    let title: String
    
    init(
      set: any GameSet,
      selectedSet: (any GameSet)?,
      index: Int,
      colorScheme: ColorScheme
    ) {
      childIndicatorImageName = "arrow.turn.down.right"
      disclosureIndicatorImageName = "chevron.right"
      iconUrl = set.iconURL
      id = set.code.uppercased()
      isSelected = selectedSet?.id == set.id
      shouldShowIndentIndicator = set.isParent == false
      numberOfCardsLabel = String(localized: "\(set.numberOfCards) Cards")
      shouldSetBackground = index.isMultiple(of: 2)
      title = set.name
      self.colorScheme = colorScheme
    }
  }
}
