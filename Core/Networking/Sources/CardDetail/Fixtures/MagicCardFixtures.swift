import Foundation

public enum MagicCardFixtures {
  case split
  
  public var value: MockMagicCard<MockMagicCardColor> {
    MagicCardBuilder<MockMagicCardColor>()
      .with(imageURL: URL(string: "https://cards.scryfall.io/normal/front/0/2/023b5e6f-10de-422d-8431-11f1fdeca246.jpg?1562895407")!)
      .with(set: "MKM")
      .with(collectorNumber: "123")
      .with(typeline: "Creature - Enchanment")
      .with(layout: .init(value: .split))
      .with(cardFaces: [
        .init(
          artist: "Jun",
          flavorText: "Flavor",
          loyalty: "1",
          name: "Jun Name",
          oracleText: "Oracle",
          power: "123",
          printedName: "Hahaha",
          printedText: """
At the beginning of each player's upkeep, Roiling Vortex deals 1 damage to them.
Whenever a player casts a spell, if no mana was spent to cast that spell, Roiling Vortex deals 5 damage to that player.
{R}: Your opponents can't gain life this turn.
""",
          printedTypeLine: "Topdecker123",
          toughness: "33",
          typeLine: "Topdecker123",
          manaCost: "{R}{1}{0}"
        ),
        .init(
          manaValue: 1,
          artist: "Jun",
          flavorText: "Flavor",
          loyalty: "1",
          name: "Jun Name",
          oracleText: "Oracle",
          power: "123",
          printedName: "Hahaha",
          printedText: "Text",
          printedTypeLine: "Topdecker123",
          toughness: "33",
          typeLine: "Topdecker123",
          manaCost: "{B}{1}{0}"
        ),
      ])
      .with(
        legalities: MockMagicCardLegalities(
          value: [
            .brawl(.legal),
            .commander(.legal),
            .historic(.legal),
            .legacy(.legal),
            .modern(.legal),
            .pauper(.legal),
            .penny(.legal),
            .pioneer(.legal),
            .standard(.legal),
            .vintage(.legal),
          ]
        )
      )
      .build()
  }
}
