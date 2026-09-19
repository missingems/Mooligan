import Foundation

/// The part of Scryfall's card object the tool reads.
struct ScryfallCard: Decodable, Sendable {
  struct Face: Decodable, Sendable {
    let name: String
    let oracleId: String?
    let illustrationId: String?
    let imageUris: [String: String]?
  }

  let id: String
  let name: String
  let set: String
  let collectorNumber: String
  let oracleId: String?
  let illustrationId: String?
  let imageUris: [String: String]?
  let cardFaces: [Face]?

  /// The faces the database stores for this printing: one for a card with a
  /// single image, otherwise one per face that has its own.
  var faces: [ScannableFace] {
    if let image = imageUris?["normal"] {
      return [ScannableFace(
        faceID: id,
        name: name,
        set: set,
        collectorNumber: collectorNumber,
        imageURL: URL(string: image),
        oracleID: oracleId ?? cardFaces?.first?.oracleId,
        illustrationID: illustrationId ?? cardFaces?.first?.illustrationId
      )]
    }
    return (cardFaces ?? []).enumerated().compactMap { index, face in
      guard let image = face.imageUris?["normal"] else { return nil }
      return ScannableFace(
        faceID: "\(id)-face\(index)",
        name: face.name,
        set: set,
        collectorNumber: collectorNumber,
        imageURL: URL(string: image),
        oracleID: oracleId ?? face.oracleId,
        illustrationID: face.illustrationId
      )
    }
  }
}
