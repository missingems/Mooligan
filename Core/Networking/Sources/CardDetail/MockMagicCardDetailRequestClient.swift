import Foundation
import ScryfallKit

public struct MockMagicCardDetailRequestClient<Card: MagicCard>: MagicCardDetailRequestClient {
  public func getVariants(of card: MockMagicCard<MockMagicCardColor>, page: Int) async throws -> [MockMagicCard<MockMagicCardColor>] {
    [card]
  }
  
  public func getSet(of card: MockMagicCard<MockMagicCardColor>) async throws -> MockGameSet {
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
