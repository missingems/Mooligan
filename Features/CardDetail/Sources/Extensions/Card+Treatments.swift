import Foundation
import ScryfallKit

extension Card {
  /// What sets this printing apart from the plain one, as collectors name it: "Borderless",
  /// "Showcase". Empty for a plain printing.
  var treatments: [String] {
    var treatments: [String] = []
    if borderColor == .borderless { treatments.append(String(localized: "Borderless")) }
    if frameEffects?.contains(.showcase) == true { treatments.append(String(localized: "Showcase")) }
    if frameEffects?.contains(.extendedArt) == true { treatments.append(String(localized: "Extended Art")) }
    if fullArt { treatments.append(String(localized: "Full Art")) }
    if frameEffects?.contains(.etched) == true { treatments.append(String(localized: "Etched")) }
    if promoTypes?.contains("serialized") == true { treatments.append(String(localized: "Serialized")) }
    return treatments
  }
}
