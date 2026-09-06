import ComposableArchitecture
import ScryfallKit

#if DEBUG
public struct MockCardQueryRequestClient: MagicCardQueryRequestClient {
  public let response: ObjectList<Card>

  public let failingFromPage: Int?

  /// When set, `queryCards` serves pages from this corpus instead of returning
  /// `response` verbatim — used by the UI-test launch mode so the grid has
  /// enough distinct, paginated cards to exercise scrolling, pagination,
  /// filtering and horizontal paging.
  private let corpus: [Card]?
  private let pageSize: Int

  public init(
    expectedResponse: ObjectList<Card> = ObjectList(data: [.mock()]),
    failingFromPage: Int? = nil
  ) {
    response = expectedResponse
    self.failingFromPage = failingFromPage
    corpus = nil
    pageSize = 12
  }

  /// `count` distinct cards ("Test Card 01"… with matching collector numbers),
  /// served `pageSize` at a time.
  public init(uiTestCorpus count: Int, pageSize: Int = 12) {
    response = ObjectList(data: [])
    failingFromPage = nil
    corpus = Self.makeCorpus(count: count)
    self.pageSize = pageSize
  }

  static func makeCorpus(count: Int) -> [Card] {
    (1...count).map { number in
      let padded = String(format: "%02d", number)
      return .mock(id: nil, name: "Test Card \(padded)", collectorNumber: padded, set: "TST")
    }
  }

  public func queryCard(for id: String) async throws -> Card {
    corpus?.first ?? response.data.first ?? .mock()
  }

  public func queryCards(_ query: SearchQuery) async throws -> ObjectList<Card> {
    if let failingFromPage, query.page >= failingFromPage {
      throw MockCardQueryRequestClientError.offline
    }

    guard let corpus else {
      return response
    }

    var filtered = corpus

    let name = query.name.trimmingCharacters(in: .whitespacesAndNewlines)
    if name.isEmpty == false {
      filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(name) }
    }

    // Any colour selection collapses the result to a fixed small subset, so a
    // filter test can assert the grid actually re-queried.
    if query.colorIdentities.isEmpty == false {
      filtered = Array(filtered.prefix(6))
    }

    let start = max(0, (query.page - 1) * pageSize)
    guard start < filtered.count else {
      return ObjectList(data: [], hasMore: false, totalCards: filtered.count)
    }
    let end = min(filtered.count, start + pageSize)

    return ObjectList(
      data: Array(filtered[start..<end]),
      hasMore: end < filtered.count,
      totalCards: filtered.count
    )
  }

  public func queryCards(_ query: QueryType) async throws -> ObjectList<Card> {
    corpus.map { ObjectList(data: Array($0.prefix(pageSize)), hasMore: $0.count > pageSize, totalCards: $0.count) }
      ?? response
  }

  public func randomlyQueryErrorCard() async throws -> Card {
    if let corpus, let first = corpus.first {
      return first
    }
    fatalError("Unimplemented")
  }
}

public enum MockCardQueryRequestClientError: Error, Equatable {
  case offline
}
#endif
