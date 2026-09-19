import Foundation
import ScryfallKit

extension Card.Color {
  var name: String {
    switch self {
    case .W: String(localized: "White")
    case .U: String(localized: "Blue")
    case .B: String(localized: "Black")
    case .R: String(localized: "Red")
    case .G: String(localized: "Green")
    case .C: String(localized: "Colorless")
    }
  }
}
