import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Scans Scryfall images of each niche in each simulated environment, and the
/// real photos in Fixtures, through the scanner's own code, and reports how
/// often the card is found and recognised.
@main
struct ScannerAccuracy {
  static func main() async throws {
    let options: Options
    do {
      options = try Options(arguments: CommandLine.arguments.dropFirst())
    } catch {
      print("scanner-accuracy: \(error). See Tools/scanner-accuracy/README.md.")
      exit(64)
    }
    try FileManager.default.createDirectory(at: options.cache, withIntermediateDirectories: true)

    // The app's own sync, into the tool's cache: the first run downloads the master.
    let manager = CardImageHashSyncManager(documentsDirectory: options.cache)
    await manager.sync()
    let index = try CardFeaturePrintIndex(contentsOf: options.cache.appendingPathComponent("MTG_Hashes.index"))
    let stored = Set(index.ids)

    let corpus = Corpus(cache: options.cache, scryfall: Scryfall())
    let composer = FrameComposer()
    var outcomes: [ScanOutcome] = []

    for niche in options.niches {
      let printings = try await corpus.printings(for: niche, refresh: options.refresh)
      // Evenly spread over the page, so a smaller sample still spans it.
      let step = max(1, printings.count / options.samples)
      let sample = stride(from: 0, to: printings.count, by: step).prefix(options.samples).map { printings[$0] }
      let faces = sample.flatMap { $0 }.filter { stored.contains($0.faceID) }

      for face in faces {
        let card = try await corpus.image(of: face)
        for environment in options.environments {
          let (frame, truth) = composer.compose(card, in: environment, seed: "\(face.faceID) \(environment)")
          let (cornerError, crop, match) = await scan(frame, truth: truth, manager: manager, context: composer.context)
          let outcome = ScanOutcome(niche: niche.name, environment: environment, expected: face, cornerError: cornerError, match: match)
          outcomes.append(outcome)
          if let frames = options.frames {
            let name = "\(niche.name) \(environment) \(face.faceID)"
            save(frame, to: frames.appendingPathComponent("\(name) frame.jpg"))
            crop.map { save($0, to: frames.appendingPathComponent("\(name) crop.jpg")) }
          }
          if let failures = options.failures, match?.id != face.faceID {
            let name = "\(niche.name) \(environment) \(face.faceID)"
            save(frame, to: failures.appendingPathComponent("\(name) frame.jpg"))
            crop.map { save($0, to: failures.appendingPathComponent("\(name) crop.jpg")) }
          }
        }
      }
      print("\(niche.name): \(faces.count) faces scanned in \(options.environments.count) environments")
    }

    let faces = try await corpus.faces(forIDs: Set(outcomes.compactMap(\.match?.id)).union(outcomes.map(\.expected.faceID)))
    Report(outcomes: outcomes, faces: faces).print()

    try await scanPhotos(manager: manager, corpus: corpus, context: composer.context)
  }

  /// The scanner's steps on one frame: find the card, flatten it, recognise it.
  private static func scan(
    _ frame: CGImage,
    truth: VNRectangleObserver.Corners?,
    manager: CardImageHashSyncManager,
    context: CIContext
  ) async -> (cornerError: Double?, crop: CGImage?, match: MatchResult?) {
    guard let corners = VNRectangleObserver(image: frame).process(),
          let crop = VNRectangleObserver.flattenedCard(in: CIImage(cgImage: frame), corners: corners, context: context) else {
      return (nil, nil, nil)
    }
    let cornerError = truth.map { cornerDistance(corners, $0, in: frame) } ?? 0
    let match = await manager.findBestMatches(for: crop).first
    return (cornerError, crop, match)
  }

  /// The farthest any detected corner is from the true one, over the card's height.
  private static func cornerDistance(
    _ found: VNRectangleObserver.Corners,
    _ truth: VNRectangleObserver.Corners,
    in frame: CGImage
  ) -> Double {
    func pixels(_ point: CGPoint) -> CGPoint {
      CGPoint(x: point.x * CGFloat(frame.width), y: point.y * CGFloat(frame.height))
    }
    let pairs = [(found.topLeft, truth.topLeft), (found.topRight, truth.topRight),
                 (found.bottomLeft, truth.bottomLeft), (found.bottomRight, truth.bottomRight)]
    let height = hypot(pixels(truth.topLeft).x - pixels(truth.bottomLeft).x, pixels(truth.topLeft).y - pixels(truth.bottomLeft).y)
    return pairs.map { hypot(pixels($0).x - pixels($1).x, pixels($0).y - pixels($1).y) }.max()! / height
  }

  /// The real photos in Fixtures, which calibrate the simulated environments.
  private static func scanPhotos(manager: CardImageHashSyncManager, corpus: Corpus, context: CIContext) async throws {
    let fixtures = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("Fixtures")
    let photos = try JSONDecoder().decode([PhotoFixture].self, from: Data(contentsOf: fixtures.appendingPathComponent("photos.json")))
    var results: [(PhotoFixture, MatchResult?, Bool)] = []
    for photo in photos {
      guard let source = CGImageSourceCreateWithURL(fixtures.appendingPathComponent(photo.file) as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { continue }
      let (cornerError, _, match) = await scan(image, truth: nil, manager: manager, context: context)
      results.append((photo, match, cornerError != nil))
    }
    let faces = try await corpus.faces(forIDs: Set(results.flatMap { [$0.0.faceID] + ($0.1.map { [$0.id] } ?? []) }))

    print("\nReal photos")
    for (photo, match, detected) in results {
      guard let expected = faces[photo.faceID] else { continue }
      let quality = MatchQuality(match: match, expected: expected, faces: faces)
      let found = match.flatMap { faces[$0.id]?.label } ?? "nothing"
      print("  \(photo.file): \(detected ? "found" : "not found"), \(quality), matched \(found)"
        + (match.map { String(format: " at %.3f", $0.distance) } ?? ""))
    }
  }

  private static func save(_ image: CGImage, to url: URL) {
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
  }
}
