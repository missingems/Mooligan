import ScryfallKit

extension Card.Legalities {
  public var all: [MagicCardLegalitiesValue] {
    [
      .standard(MagicCardLegality(rawValue: standard?.rawValue ?? "") ?? .notLegal),
      .historic(MagicCardLegality(rawValue: historic?.rawValue ?? "") ?? .notLegal),
      .pioneer(MagicCardLegality(rawValue: pioneer?.rawValue ?? "") ?? .notLegal),
      .modern(MagicCardLegality(rawValue: modern?.rawValue ?? "") ?? .notLegal),
      .legacy(MagicCardLegality(rawValue: legacy?.rawValue ?? "") ?? .notLegal),
      .pauper(MagicCardLegality(rawValue: pauper?.rawValue ?? "") ?? .notLegal),
      .vintage(MagicCardLegality(rawValue: vintage?.rawValue ?? "") ?? .notLegal),
      .penny(MagicCardLegality(rawValue: penny?.rawValue ?? "") ?? .notLegal),
      .commander(MagicCardLegality(rawValue: commander?.rawValue ?? "") ?? .notLegal),
      .brawl(MagicCardLegality(rawValue: brawl?.rawValue ?? "") ?? .notLegal),
    ]
  }
}
