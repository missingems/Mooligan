import ComposableArchitecture
import ScryfallKit

#if DEBUG
public struct MockCardQueryRequestClient: MagicCardQueryRequestClient {
  public let response: ObjectList<Card>

  public let failingFromPage: Int?

  public init(
    expectedResponse: ObjectList<Card> = ObjectList(data: [.mock()]),
    failingFromPage: Int? = nil
  ) {
    response = expectedResponse
    self.failingFromPage = failingFromPage
  }

  public func queryCard(for id: String) async throws -> Card {
    response.data.first!
  }

  public func queryCards(_ query: SearchQuery) async throws -> ObjectList<Card> {
    if let failingFromPage, query.page >= failingFromPage {
      throw MockCardQueryRequestClientError.offline
    }

    return response
  }

  public func queryCards(_ query: QueryType) async throws -> ObjectList<Card> {
    response
  }

  public func randomlyQueryErrorCard() async throws -> Card {
    fatalError("Unimplemented")
  }
}

public enum MockCardQueryRequestClientError: Error, Equatable {
  case offline
}
#endif
