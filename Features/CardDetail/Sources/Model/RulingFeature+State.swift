import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit

public extension RulingFeature {
  @ObservableState struct State: Equatable {
    enum Mode: Equatable {
      case loading
      case loaded([MagicCardRuling])
    }
    
    let card: Card
    let title: String
    var mode: Mode = .loading
    
    var emptyStateTitle: String {
      return "No Results for \"\(card.name)\""
    }
    
    var emptyStateDescription: String? {
      if let url = card.getGathererURLString() {
        return "Look up \(url) for more information."
      } else {
        return nil
      }
    }
  }
}
