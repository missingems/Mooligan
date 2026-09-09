import Networking
import Nuke
import SwiftUI

/// Where a product's real wrapper photograph lives.
///
/// Arcane Assets hosts a photo of each sealed product at a predictable path,
/// and has said it is fine to read as a public API. Coverage is partial —
/// plenty of sets have no image at all — so this is only ever an upgrade over
/// the drawn wrapper, never a requirement: anything that 404s or fails to load
/// falls back to `BoosterPackArtwork`.
enum PackWrapperArt {
  static func url(for product: PackProduct) -> URL? {
    // The slugs line up with what the shelf already offers: `stockedPackKinds`
    // only sells `.play` for 2024-on sets and `.draft` for older ones, which is
    // exactly the split Arcane Assets files them under.
    let slug =
      switch product.kind {
      case .play: "play"
      case .draft: "draft"
      case .collector: "collector"
      }

    return URL(
      string:
        "https://www.arcane-assets.com/sealed_products/\(product.set.code.lowercased())/\(slug).png"
    )
  }
}

/// Loads the wrapper photograph for one product, once.
///
/// Held as `@State` by whichever view needs the artwork so the result survives
/// redraws — the tear in particular redraws at display rate, and re-deciding
/// which artwork to use mid-drag would swap the wrapper out from under the
/// gesture.
@MainActor
@Observable
final class PackWrapperArtLoader {
  private(set) var photo: Image?

  /// The photograph's own width-to-height ratio, which is not quite the drawn
  /// wrapper's: the tear sizes itself to this so the torn shapes cut across
  /// what is actually on screen rather than a slightly different box.
  private(set) var aspectRatio: CGFloat?

  /// `true` once the fetch has settled either way, so callers can tell "no
  /// photo yet" from "this product has none".
  private(set) var hasSettled = false

  func load(for product: PackProduct) async {
    guard hasSettled == false, let url = PackWrapperArt.url(for: product) else { return }

    if let image = try? await ImagePipeline.shared.image(for: url), image.size.height > 0 {
      photo = Image(uiImage: image)
      aspectRatio = image.size.width / image.size.height
    }
    hasSettled = true
  }
}
