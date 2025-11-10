import Networking
import SwiftUI
import ScryfallKit

public extension Card.Color {
  var image: Image {
    Image("{\(rawValue)}", bundle: DesignComponentsResources.bundle)
  }
  
  var name: String {
    return switch self {
    case .W: 
      "White"
    case .U:
      "Blue"
    case .B:
      "Black"
    case .R:
      "Red"
    case .G:
      "Green"
    case .C:
      "Colorless"
    }
  }
}
