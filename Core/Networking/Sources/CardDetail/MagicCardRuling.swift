import Foundation

public struct MagicCardRuling: Sendable, Equatable, Identifiable {
  public let id: UUID
  public let displayDate: String
  public let description: String
  
  public init(displayDate: String, description: String) {
    self.displayDate = displayDate
    self.description = description
    self.id = UUID()
  }
}
