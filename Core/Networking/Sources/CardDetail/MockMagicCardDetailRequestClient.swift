import Foundation
import ScryfallKit

public struct MockMagicCardDetailRequestClient<Card: MagicCard>: MagicCardDetailRequestClient {
  public func getVariants(of card: Card, page: Int) async throws -> [Card] {
    []
  }
  
  public func getSet(of card: Card) async throws -> MockGameSet {
    MockGameSet(
      isParent: true,
      id: UUID(),
      code: "123",
      numberOfCards: 123,
      name: "123",
      iconURL: URL(string: "https://mooligan.com")
    )
  }
  
  public init() {}
}
