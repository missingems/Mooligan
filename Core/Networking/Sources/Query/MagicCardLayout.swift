import ScryfallKit

public extension Card.Layout {
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
