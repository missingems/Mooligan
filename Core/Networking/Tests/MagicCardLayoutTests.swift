@testable import Networking
import Foundation
import ScryfallKit
import Testing

/// Covers which layouts the card detail table shows side by side, and which card images lie on
/// their side. Scryfall adds layouts over time, and ScryfallKit turns a new one from `.unknown`
/// into a named case, which is how `prepare` cards lost their second column.
struct MagicCardLayoutTests {
  private func card(_ layout: Card.Layout) -> Card {
    var card = Card.mock()
    card.layout = layout
    return card
  }

  @Test(arguments: [Card.Layout.split, .adventure, .prepare])
  func twoHalvesOnOneFaceShouldShowTwoColumns(_ layout: Card.Layout) {
    #expect(card(layout).hasMultipleColumns)
  }

  @Test(arguments: [
    Card.Layout.normal, .flip, .transform, .modalDfc, .meld, .saga, .class, .case, .battle,
    .reversibleCard, .doubleFacedToken,
  ])
  func oneCardPerFaceShouldShowOneColumn(_ layout: Card.Layout) {
    #expect(card(layout).hasMultipleColumns == false)
  }

  @Test func anUnknownLayoutShouldFollowItsFaces() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let face = try decoder.decode(Card.Face.self, from: Data(#"{"name": "Half", "mana_cost": "{1}"}"#.utf8))

    var twoFaces = card(.unknown("future_layout"))
    twoFaces.cardFaces = [face, face]
    #expect(twoFaces.hasMultipleColumns)

    var oneFace = card(.unknown("future_layout"))
    oneFace.cardFaces = [face]
    #expect(oneFace.hasMultipleColumns == false)
  }

  @Test func onlySplitCardsShouldLieOnTheirSide() {
    #expect(card(.split).isLandscape)
    #expect(card(.adventure).isLandscape == false)
    #expect(card(.prepare).isLandscape == false)
    #expect(card(.transform).isLandscape == false)
  }
}
