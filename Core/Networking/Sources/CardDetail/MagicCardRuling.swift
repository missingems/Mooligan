import Foundation

public struct MagicCardRuling: Sendable, Equatable, Identifiable {
  public let id: UUID
  public let displayDate: String
  public let description: [[TextElement]]
  
  public init(displayDate: String, description: [[TextElement]]) {
    self.displayDate = displayDate
    self.description = description
    self.id = UUID()
  }
}
