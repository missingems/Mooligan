import ScryfallKit

extension Card.Color: MagicCardColor {
  public var value: MagicCardColorValue {
    MagicCardColorValue(rawValue: rawValue) ?? .none
  }
}
