import ComposableArchitecture
import ScryfallKit

public struct MockCardQueryRequestClient: MagicCardQueryRequestClient {
  public func queryCards(_ query: Query) async throws -> ScryfallKit.ObjectList<ScryfallKit.Card> {
    response
  }
  
  public let response: ObjectList<Card>
  
  public init(expectedResponse: ObjectList<Card> = ObjectList(data: [.mock()])) {
    response = expectedResponse
  }
  
  public func queryCards(_ query: QueryType) async throws -> ScryfallKit.ObjectList<ScryfallKit.Card> {
    response
  }
}
