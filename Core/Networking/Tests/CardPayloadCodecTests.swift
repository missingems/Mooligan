@testable import Networking
import Foundation
import ScryfallKit
import Testing

struct CardPayloadCodecTests {
  @Test func whenRoundTrippingACard_shouldPreserveEveryField() throws {
    let card = CardFixtures.card(name: "Birds of Paradise", colorIdentity: [.G])

    let decoded = try CardPayloadCodec.decode(CardPayloadCodec.encode(card))

    #expect(decoded == card)
  }

  @Test func whenRoundTrippingNestedStructures_shouldPreserveThem() throws {
    var card = CardFixtures.card()
    card.cardFaces = [
      Card.Face(
        manaCost: "{R}", name: "Front", oracleText: "Deal 3 damage.", typeLine: "Instant"
      ),
      Card.Face(
        manaCost: "", name: "Back", oracleText: "Tap for {R}.", typeLine: "Land"
      ),
    ]
    card.allParts = [
      Card.RelatedCard(
        id: UUID(),
        component: .token,
        name: "Goblin",
        typeLine: "Token Creature — Goblin",
        uri: "https://api.scryfall.com/cards/1"
      )
    ]
    card.keywords = ["Flying", "Haste"]

    let decoded = try CardPayloadCodec.decode(CardPayloadCodec.encode(card))

    #expect(decoded.cardFaces?.count == 2)
    #expect(decoded.cardFaces?.first?.name == "Front")
    #expect(decoded.allParts?.first?.component == .token)
    #expect(decoded.keywords == ["Flying", "Haste"])
    #expect(decoded == card)
  }

  @Test func whenDecodingScryfallJSON_shouldConvertSnakeCaseKeys() throws {
    let card = CardFixtures.card(collectorNumber: "42")
    var json = try JSONSerialization.jsonObject(
      with: JSONEncoder().encode(card)
    ) as! [String: Any]

    json["collector_number"] = json.removeValue(forKey: "collectorNumber")
    json["oracle_id"] = json.removeValue(forKey: "oracleId")
    json["released_at"] = json.removeValue(forKey: "releasedAt")
    json["set_id"] = json.removeValue(forKey: "setId")
    json["set_name"] = json.removeValue(forKey: "setName")
    json["color_identity"] = json.removeValue(forKey: "colorIdentity")
    json["image_status"] = json.removeValue(forKey: "imageStatus")
    json["border_color"] = json.removeValue(forKey: "borderColor")
    json["set_search_uri"] = json.removeValue(forKey: "setSearchUri")
    json["scryfall_set_uri"] = json.removeValue(forKey: "scryfallSetUri")
    json["set_uri"] = json.removeValue(forKey: "setUri")
    json["prints_search_uri"] = json.removeValue(forKey: "printsSearchUri")
    json["rulings_uri"] = json.removeValue(forKey: "rulingsUri")
    json["scryfall_uri"] = json.removeValue(forKey: "scryfallUri")
    json["related_uris"] = json.removeValue(forKey: "relatedUris")
    json["highres_image"] = json.removeValue(forKey: "highresImage")
    json["type_line"] = json.removeValue(forKey: "typeLine")
    json["story_spotlight"] = json.removeValue(forKey: "storySpotlight")
    json["full_art"] = json.removeValue(forKey: "fullArt")
    json["set_type"] = json.removeValue(forKey: "setType")
    json["image_uris"] = json.removeValue(forKey: "imageUris")

    let decoded = try CardPayloadCodec.decodeScryfall(
      JSONSerialization.data(withJSONObject: json)
    )

    #expect(decoded.collectorNumber == "42")
    #expect(decoded.id == card.id)
    #expect(decoded.setId == card.setId)
  }

  @Test func whenEncoding_shouldCompressBelowThePlainJSONSize() throws {
    let card = CardFixtures.card()
    let plain = try JSONEncoder().encode(card)

    let payload = try CardPayloadCodec.encode(card)

    #expect(payload.count < plain.count)
  }
}
