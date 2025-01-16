import ScryfallKit

public enum QueryType: Equatable {
  case search(Query)
  case querySet(MTGSet, Query)
}
