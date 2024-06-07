import Foundation
import ScryfallKit

struct TestMagicCardDetailRequestClient: MagicCardDetailRequestClient {
  func getVariants(of card: Card, page: Int) async throws -> [Card] {
    MagicCardFixture.stub
  }
  
  func getSet(of card: Card) async throws -> MockGameSet {
    MockGameSet(
      isParent: true,
      id: UUID(),
      code: "123",
      numberOfCards: 123,
      name: "123",
      iconURL: nil
    )
  }
}
