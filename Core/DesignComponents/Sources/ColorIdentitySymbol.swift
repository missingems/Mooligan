import Networking
import SwiftUI
import ScryfallKit

public extension Card.Color {
  var image: Image {
    Image("{\(rawValue)}", bundle: DesignComponentsResources.bundle)
  }
}
