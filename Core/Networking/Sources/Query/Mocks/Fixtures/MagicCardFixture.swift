import ScryfallKit

struct MagicCardFixture {
  @Decode("cards.json")
  static var stub: [Card]
}
