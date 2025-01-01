import ComposableArchitecture
import ScryfallKit

public struct MockCardQueryRequestClient: MagicCardQueryRequestClient {
  public func queryCards(_ query: QueryType) async throws -> ScryfallKit.ObjectList<ScryfallKit.Card> {
    ObjectList(data: [.mock])
  }
}
