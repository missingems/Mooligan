public enum MagicCardFaceDirection: Sendable, Equatable {
  case front
  case back
  
  public func toggled() -> Self {
    switch self {
    case .back:
      return .front
      
    case .front:
      return .back
    }
  }
}
