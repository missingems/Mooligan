import ScryfallKit

public struct MagicCardFixture {
  @Decode<[Card]>("cards.json")
  public static var stub
}
