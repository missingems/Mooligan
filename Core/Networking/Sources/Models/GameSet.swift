import Foundation

public protocol GameSet: Equatable, Hashable, Identifiable {
  var id: UUID { get }
  var code: String { get }
  var numberOfCards: Int { get }
  var name: String { get }
  var iconURL: URL? { get }
}
