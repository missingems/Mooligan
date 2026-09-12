import Networking
import ScryfallKit
import SwiftUI

/// The colour scheme a wrapper is printed in.
///
/// Real boosters are art-directed per set, and we have no artwork for them, so
/// the palette is derived from the set code instead: the same set always prints
/// the same wrapper, and neighbouring sets on the shelf look distinct.
struct PackTheme: Equatable {
  let base: Color
  let highlight: Color
  let shadow: Color
  let accent: Color

  /// Whether the set name and label strip should be drawn dark.
  let prefersDarkInk: Bool

  init(setCode: String, kind: BoosterPackKind) {
    let hue = Self.hue(forSetCode: setCode)

    switch kind {
    case .play:
      base = Color(hue: hue, saturation: 0.62, brightness: 0.52)
      highlight = Color(hue: hue, saturation: 0.34, brightness: 0.92)
      shadow = Color(hue: hue, saturation: 0.85, brightness: 0.22)
      accent = Color(hue: (hue + 0.5).truncatingRemainder(dividingBy: 1), saturation: 0.5, brightness: 0.95)
      prefersDarkInk = false

    case .draft:
      base = Color(hue: hue, saturation: 0.45, brightness: 0.62)
      highlight = Color(hue: hue, saturation: 0.2, brightness: 0.96)
      shadow = Color(hue: hue, saturation: 0.7, brightness: 0.3)
      accent = Color(hue: hue, saturation: 0.15, brightness: 1)
      prefersDarkInk = true

    case .collector:
      // Collector boosters are the black-and-gold ones.
      base = Color(hue: hue, saturation: 0.35, brightness: 0.16)
      highlight = Color(hue: 0.11, saturation: 0.55, brightness: 0.86)
      shadow = .black
      accent = Color(hue: 0.11, saturation: 0.62, brightness: 0.98)
      prefersDarkInk = false
    }
  }

  /// Stable hue in `0..<1` from the set code, spread with a large odd
  /// multiplier so "MKM" and "MOM" do not land on the same colour.
  private static func hue(forSetCode code: String) -> Double {
    let value = code.uppercased().unicodeScalars.reduce(UInt64(17)) { partial, scalar in
      partial &* 31 &+ UInt64(scalar.value)
    }

    return Double(value % 997) / 997
  }

  /// The wrapper's body, lit from the upper left.
  var bodyGradient: LinearGradient {
    LinearGradient(
      colors: [highlight, base, shadow, base.opacity(0.9), highlight.opacity(0.75)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  var inkColor: Color {
    prefersDarkInk ? .black.opacity(0.75) : .white
  }
}

extension Card.Rarity {
  /// Glow used behind a card as it is revealed.
  var revealGlow: Color {
    switch self {
    case .mythic: Color(red: 1, green: 0.42, blue: 0.11)
    case .rare: Color(red: 0.98, green: 0.79, blue: 0.35)
    case .special, .bonus: Color(red: 0.75, green: 0.45, blue: 0.95)
    case .uncommon: Color(red: 0.68, green: 0.76, blue: 0.82)
    case .common: Color(white: 0.55)
    }
  }

  var displayName: String {
    switch self {
    case .mythic: String(localized: "Mythic Rare")
    case .rare: String(localized: "Rare")
    case .special: String(localized: "Special")
    case .bonus: String(localized: "Bonus")
    case .uncommon: String(localized: "Uncommon")
    case .common: String(localized: "Common")
    }
  }
}
