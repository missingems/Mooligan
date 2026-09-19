import CoreGraphics
import Foundation
import ImageIO

/// The printings to scan, their images, and what any matched face is. All come
/// from Scryfall once and are cached, so a rerun measures the same cards.
struct Corpus {
  let cache: URL
  let scryfall: Scryfall

  /// Printings from up to four pages spread across the niche's search, from its
  /// oldest to its newest, as the faces of each printing.
  func printings(for niche: Niche, refresh: Bool) async throws -> [[ScannableFace]] {
    let url = cache.appendingPathComponent("niches").appendingPathComponent("\(niche.name).json")
    if !refresh, let data = try? Data(contentsOf: url),
       let printings = try? JSONDecoder().decode([[ScannableFace]].self, from: data) {
      return printings
    }
    let first = try await scryfall.search(niche.query, page: 1)
    let pageCount = (first.total + 174) / 175
    var cards = first.cards
    for page in Set((1...3).map { 1 + $0 * (pageCount - 1) / 3 }).subtracting([1]).sorted() {
      cards += try await scryfall.search(niche.query, page: page).cards
    }
    let printings = cards.map(\.faces).filter { !$0.isEmpty }
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try JSONEncoder().encode(printings).write(to: url)
    return printings
  }

  /// The face's Scryfall image.
  func image(of face: ScannableFace) async throws -> CGImage {
    let url = cache.appendingPathComponent("images").appendingPathComponent("\(face.faceID).jpg")
    if !FileManager.default.fileExists(atPath: url.path) {
      guard let remote = face.imageURL else { throw URLError(.badURL) }
      let (data, _) = try await URLSession.shared.data(from: remote)
      try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      try data.write(to: url)
    }
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      throw CocoaError(.fileReadCorruptFile)
    }
    return image
  }

  /// What each database face id is.
  func faces(forIDs ids: Set<String>) async throws -> [String: ScannableFace] {
    let url = cache.appendingPathComponent("faces.json")
    var known = (try? JSONDecoder().decode([String: ScannableFace].self, from: Data(contentsOf: url))) ?? [:]
    let cardIDs = Set(ids.subtracting(known.keys).map { MatchResult(id: $0, distance: 0).cardID })
    if !cardIDs.isEmpty {
      for card in try await scryfall.cards(cardIDs.sorted()) {
        for face in card.faces { known[face.faceID] = face }
      }
      try JSONEncoder().encode(known).write(to: url)
    }
    return known
  }
}
