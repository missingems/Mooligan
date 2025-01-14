import ScryfallKit

public enum QueryType: Equatable {
  case search(String, page: Int)
  case query(MTGSet, [CardFieldFilter], SortMode, SortDirection, page: Int)
  
  public func next() -> Self {
    switch self {
    case let .search(text, page):
      return .search(text, page: page + 1)
      
    case let .query(set, filter, sortMode, sortDirection, page):
      return .query(set, filter, sortMode, sortDirection, page: page + 1)
    }
  }
  
  public var page: Int {
    switch self {
    case let .search(_, page):
      return page
      
    case .query(_, _, _, _, page: let page):
      return page
    }
  }
  
  public static func == (lhs: QueryType, rhs: QueryType) -> Bool {
    switch (lhs, rhs) {
    case let (.search(lhsText, lhsPage), .search(rhsText, rhsPage)):
      return lhsText == rhsText && lhsPage == rhsPage
      
    case let (.query(lhsGameSet, lhsFilter, lhsSortMode, lhsSortDirection, lhsPage), .query(rhsGameSet, rhsFilter, rhsSortMode, rhsSortDirection, rhsPage)):
      return lhsGameSet.id == rhsGameSet.id && lhsFilter == rhsFilter && lhsSortMode == rhsSortMode && lhsSortDirection == rhsSortDirection && lhsPage == rhsPage
      
    default:
      return false
    }
  }
}

extension CardFieldFilter: @retroactive Equatable {
  public static func == (lhs: CardFieldFilter, rhs: CardFieldFilter) -> Bool {
    return lhs.filterString == rhs.filterString
  }
}
