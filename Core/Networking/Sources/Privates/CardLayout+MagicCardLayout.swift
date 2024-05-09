import ScryfallKit

extension Card.Layout: MagicCardLayout {
  public var value: MagicCardLayoutValue {
    MagicCardLayoutValue(rawValue: rawValue) ?? .unknown
  }
}
