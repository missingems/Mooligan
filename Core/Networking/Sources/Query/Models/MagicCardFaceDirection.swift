public enum MagicCardFaceDirection: Sendable, Equatable, Identifiable {
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
  
  public var id: String {
    switch self {
    case .front: return "front"
    case .back: return "back"
    }
  }
}
