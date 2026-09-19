import Foundation

public struct MatchResult: Sendable, Equatable {
  public let id: String
  public let distance: Float

  public init(id: String, distance: Float) {
    self.id = id
    self.distance = distance
  }

  /// The Scryfall card the match belongs to. The database stores a card whose
  /// faces have their own images (transform, modal double-faced, battle,
  /// reversible) once per face, as `<card id>-face<index>`, and Scryfall only
  /// knows the card id.
  public var cardID: String { face?.cardID ?? id }

  /// Which face matched, for cards stored face by face; nil for a card with one image.
  public var faceIndex: Int? { face?.index }

  /// Only an exact `<36-character card id>-face<digits>` counts: a few plain
  /// card ids contain "-face" themselves, like 9f4dee38-face-439a-a815-b6c6aab3ca43.
  private var face: (cardID: String, index: Int)? {
    let cardID = String(id.prefix(36)), suffix = id.dropFirst(36)
    guard UUID(uuidString: cardID) != nil, suffix.hasPrefix("-face"),
          let index = Int(suffix.dropFirst(5)), index >= 0 else { return nil }
    return (cardID, index)
  }
}
