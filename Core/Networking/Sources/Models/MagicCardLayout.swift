public enum MagicCardLayoutValue: String, Equatable, Sendable {
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

public protocol MagicCardLayout {
  var value: MagicCardLayoutValue { get }
}
