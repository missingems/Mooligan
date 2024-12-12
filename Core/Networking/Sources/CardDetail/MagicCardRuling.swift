import Foundation

public struct MagicCardRuling: Sendable, Equatable {
  public let displayDate: String
  public let description: String
  
  public init(displayDate: String, description: String) {
    self.displayDate = displayDate
    self.description = description
  }
}
