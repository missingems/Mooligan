/// How close a match is to the face that was scanned.
enum MatchQuality: Comparable {
  case none
  case wrongCard
  /// The same card in another printing with different art.
  case sameCard
  /// Another printing with the same art, which no scanner can tell apart.
  case sameArt
  case exactPrinting

  init(match: MatchResult?, expected: ScannableFace, faces: [String: ScannableFace]) {
    guard let match else { self = .none; return }
    if match.id == expected.faceID {
      self = .exactPrinting
    } else if let found = faces[match.id], let art = found.illustrationID, art == expected.illustrationID {
      self = .sameArt
    } else if let found = faces[match.id], let card = found.oracleID, card == expected.oracleID {
      self = .sameCard
    } else {
      self = .wrongCard
    }
  }
}
