public enum MagicCardLayoutValue: String, Equatable, Sendable, Hashable {
  case normal
  case split
  case flip
  case transform
  case meld
  case leveler
  case saga
  case adventure
  case planar
  case scheme
  case vanguard
  case token
  case emblem
  case augment
  case host
  case `class`
  case battle
  case `case`
  case mutate
  case unknown
  case modalDfc = "modal_dfc"
  case doubleSided = "double_sided"
  case doubleFacedToken = "double_faced_token"
  case artSeries = "art_series"
  case reversibleCard = "reversible_card"
}

public protocol MagicCardLayout: Sendable, Equatable, Hashable {
  var value: MagicCardLayoutValue { get }
}

public extension MagicCardLayoutValue {
  var callToActionLabel: String? {
    switch self {
    case .flip:
      return "Flip"
    case .transform:
      return "Transform"
    case .modalDfc:
      return "Turn Over"
    case .doubleSided:
      return "Turn Over"
    case .doubleFacedToken:
      return "Turn Over"
    case .reversibleCard:
      return "Turn Over"
    default:
      return nil
    }
  }
  
  var callToActionIconName: String? {
    switch self {
    case .flip:
      return "arrow.trianglehead.clockwise.rotate.90"
    case .transform:
      return "arrow.left.arrow.right"
    case .modalDfc:
      return "arrowshape.turn.up.left.fill"
    case .doubleSided:
      return "arrowshape.turn.up.left.fill"
    case .doubleFacedToken:
      return "arrowshape.turn.up.left.fill"
    case .reversibleCard:
      return "arrowshape.turn.up.left.fill"
    default:
      return nil
    }
  }
}
