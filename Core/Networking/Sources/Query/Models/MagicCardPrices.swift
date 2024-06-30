public protocol MagicCardPrices: Equatable, Sendable, Hashable {
  var tix: String? { get }
  var usd: String? { get }
  var usdFoil: String? { get }
  var eur: String? { get }
}
