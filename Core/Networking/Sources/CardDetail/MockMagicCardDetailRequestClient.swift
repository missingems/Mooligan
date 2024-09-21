import Foundation
import ScryfallKit

public struct MockMagicCardDetailRequestClient<Card: MagicCard>: MagicCardDetailRequestClient {
  public enum MockError: Error {
    case variantsError
    case setError
  }
  
  public enum TestConfiguration: Sendable, Equatable {
    case successFlow
    case failureFlow
  }
  
  let testConfiguration: TestConfiguration
  
  public init(testConfiguration: TestConfiguration) {
    self.testConfiguration = testConfiguration
  }
  
  public func getVariants(
    of card: MockMagicCard<MockMagicCardColor>,
    page: Int
  ) async throws -> [MockMagicCard<MockMagicCardColor>] {
    switch testConfiguration {
    case .successFlow:
      return [card]
      
    case .failureFlow:
      throw MockError.variantsError
    }
  }
  
  public func getSet(
    of card: MockMagicCard<MockMagicCardColor>
  ) async throws -> MockGameSet {
    switch testConfiguration {
    case .successFlow:
      return MockGameSet(
        isParent: true,
        id: UUID(),
        code: "123",
        numberOfCards: 123,
        name: "123",
        iconURL: URL(string: "https://mooligan.com")
      )
      
    case .failureFlow:
      throw MockError.setError
    }
  }
}
