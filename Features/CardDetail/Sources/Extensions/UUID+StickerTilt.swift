import Foundation

extension UUID {
  /// Degrees a sticker is stuck on crooked by, between 3 and 8 either way. Read from the id's own
  /// bytes rather than its hash, which Swift seeds afresh on every launch, so a card's sticker leans
  /// the same way every time it is opened.
  var stickerTilt: Double {
    let magnitude = 3 + Double(uuid.0) / 255 * 5
    return uuid.1.isMultiple(of: 2) ? magnitude : -magnitude
  }
}
