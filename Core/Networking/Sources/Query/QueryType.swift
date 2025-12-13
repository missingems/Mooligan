import ScryfallKit

@MainActor public enum QueryType: Equatable, Sendable {
  case search(SearchQuery)
  case querySet(MTGSet, SearchQuery)
}
