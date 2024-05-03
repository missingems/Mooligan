import Foundation
import SwiftUI

extension SetRow {
  struct ViewModel: Equatable {
    let childIndicatorImageName: String
    let disclosureIndicatorImageName: String
    let iconUrl: URL?
    let id: String
    var colorScheme: ColorScheme
    var isSelected: Bool
    let shouldShowIndentIndicator: Bool
    let numberOfCardsLabel: String
    let shouldSetBackground: Bool
    let title: String
    
    init(
      iconURL: URL?,
      id: String,
      colorScheme: ColorScheme,
      isSelected: Bool,
      index: Int,
      numberOfCards: Int,
      shouldShowIndentIndicator: Bool,
      title: String
    ) {
      childIndicatorImageName = "arrow.turn.down.right"
      disclosureIndicatorImageName = "chevron.right"
      iconUrl = iconURL
      self.id = id.uppercased()
      self.colorScheme = colorScheme
      self.isSelected = isSelected
      self.shouldShowIndentIndicator = shouldShowIndentIndicator
      numberOfCardsLabel = String(localized: "\(numberOfCards) Cards")
      shouldSetBackground = index.isMultiple(of: 2)
      self.title = title
    }
  }
}
