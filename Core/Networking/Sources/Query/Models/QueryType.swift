public enum QueryType: Equatable, Sendable {
  case set(any GameSet, page: Int)
  case search(String, page: Int)
  
  public func next() -> Self {
    switch self {
    case let .search(text, page):
      return .search(text, page: page + 1)
      
    case let .set(gameSet, page):
      return .set(gameSet, page: page + 1)
    }
  }
  
  public var page: Int {
    switch self {
    case let .set(_, page):
      return page
      
    case let .search(_, page):
      return page
    }
  }
  
  public static func == (lhs: QueryType, rhs: QueryType) -> Bool {
    switch (lhs, rhs) {
    case let (.set(lhsGameSet, lhsPage), .set(rhsGameSet, rhsPage)):
      return lhsGameSet.id == rhsGameSet.id && lhsPage == rhsPage
      
    case let (.search(lhsText, lhsPage), .search(rhsText, rhsPage)):
      return lhsText == rhsText && lhsPage == rhsPage
      
    default:
      return false
    }
  }
}
