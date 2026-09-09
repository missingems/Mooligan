import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import Nuke

/// Pulls a pack's card art into the shared image cache before the pack is
/// opened.
///
/// The reveal is one card after another with nothing between them, so a card
/// that is still downloading when it reaches the top of the stack shows as a
/// grey rectangle in the middle of the moment the screen exists for. Fetching
/// the whole pack up front costs a few seconds once, against a placeholder
/// flashing up to fifteen times.
public protocol PackImagePrefetching: Sendable {
  /// Fetches every image, reporting completion as a fraction of the whole.
  ///
  /// Never throws: a card whose art will not download is still a card the pack
  /// contains, and holding the pack shut over it would be worse than the
  /// placeholder this was meant to avoid.
  func prefetch(_ images: [PackImage], onProgress: @escaping @Sendable (Double) -> Void) async
}

/// One image the pack will need.
///
/// Carries the landscape flag as well as the URL because the card views rotate
/// landscape printings through an `ImageProcessing` step, and Nuke keys its
/// cache on the processors as well as the URL. Prefetching the bare URL would
/// therefore miss for exactly those cards — they would download a second time
/// and fade in on arrival, which is the thing the prefetch exists to stop.
public struct PackImage: Sendable, Equatable {
  public let url: URL
  public let isLandscape: Bool

  public init(url: URL, isLandscape: Bool) {
    self.url = url
    self.isLandscape = isLandscape
  }

  /// The same request `CardRemoteImageView` will build for this card.
  var request: ImageRequest {
    ImageRequest(
      url: url,
      processors: isLandscape ? [RotationImageProcessor(degrees: 90)] : [],
      priority: .high
    )
  }
}

public extension BoosterPack {
  /// Everything the pack will draw, in the order it will be wanted.
  var packImages: [PackImage] {
    revealOrder.compactMap { pulled in
      pulled.imageURL.map { PackImage(url: $0, isLandscape: pulled.card.isLandscape) }
    }
  }
}

public enum PackImagePrefetcherKey: DependencyKey {
  public static var liveValue: any PackImagePrefetching { NukePackImagePrefetcher() }

#if DEBUG
  /// Tests and previews have no network; report instant readiness rather than
  /// leaving the pack stuck behind a download that will never finish.
  public static var previewValue: any PackImagePrefetching { ImmediatePackImagePrefetcher() }
  public static var testValue: any PackImagePrefetching { ImmediatePackImagePrefetcher() }
#endif
}

public extension DependencyValues {
  var packImagePrefetcher: any PackImagePrefetching {
    get { self[PackImagePrefetcherKey.self] }
    set { self[PackImagePrefetcherKey.self] = newValue }
  }
}

/// Fetches through the same `ImagePipeline` the card views read from, so a
/// prefetched image is already decoded and in memory by the time a
/// `CardRemoteImageView` asks for it.
public struct NukePackImagePrefetcher: PackImagePrefetching {
  public init() {}

  public func prefetch(_ images: [PackImage], onProgress: @escaping @Sendable (Double) -> Void) async {
    guard images.isEmpty == false else { return onProgress(1) }

    let total = images.count
    let counter = ProgressCounter()

    await withTaskGroup(of: Void.self) { group in
      for image in images {
        group.addTask {
          // A failure is deliberately swallowed: `onProgress` still has to
          // advance, or one dead URL holds the pack shut.
          _ = try? await ImagePipeline.shared.image(for: image.request)
          let done = await counter.increment()
          onProgress(Double(done) / Double(total))
        }
      }
    }
  }
}

private actor ProgressCounter {
  private var count = 0

  func increment() -> Int {
    count += 1
    return count
  }
}

#if DEBUG
public struct ImmediatePackImagePrefetcher: PackImagePrefetching {
  public init() {}

  public func prefetch(_ images: [PackImage], onProgress: @escaping @Sendable (Double) -> Void) async {
    onProgress(1)
  }
}
#endif
