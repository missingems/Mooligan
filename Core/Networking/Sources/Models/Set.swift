import Foundation

public protocol Set {
  var id: String { get }
  var numberOfCards: Int { get }
  var name: String { get }
  var iconURL: URL? { get }
}
