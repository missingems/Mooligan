public enum MagicCardQueryType: Equatable {
  case set(any GameSet, page: Int)
  case search(String, page: Int)
  
  public static func == (lhs: MagicCardQueryType, rhs: MagicCardQueryType) -> Bool {
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
