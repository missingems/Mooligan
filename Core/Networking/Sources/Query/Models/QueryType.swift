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
  
  public static func == (lhs: QueryType, rhs: QueryType) -> Bool {
    switch (lhs, rhs) {
    case let (.set(lhsGameSet, _), .set(rhsGameSet, _)):
      return lhsGameSet.id == rhsGameSet.id
      
    case let (.search(lhsText, _), .search(rhsText, page: _)):
      return lhsText == rhsText
      
    default:
      return false
    }
  }
}
