public enum MagicCardColorValue: String, Equatable, Sendable {
  case white = "W"
  case blue = "U"
  case black = "B"
  case red = "R"
  case green = "G"
  case colorless = "C"
  case none = ""
}

public protocol MagicCardColor {
  var value: MagicCardColorValue { get }
}
