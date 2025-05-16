import ScryfallKit

public enum QueryType: Equatable {
  case search(SearchQuery)
  case querySet(MTGSet, SearchQuery)
}
