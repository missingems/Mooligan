import Networking
import Nuke
import UIKit
import SwiftUI

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
    guard hasSettled == false else { return }

    // Sources in order of preference; the first that actually returns a
    // picture wins, and running out of them is what leaves `photo` nil and
    // hands the wrapper back to `BoosterPackArtwork`.
    for url in PackArtwork.urls(for: product) {
      guard let image = try? await ImagePipeline.shared.image(for: url), image.size.height > 0
      else { continue }

      let trimmed = image.trimmingTransparentEdges() ?? image
      guard trimmed.size.height > 0 else { continue }

      photo = Image(uiImage: trimmed)
      aspectRatio = trimmed.size.width / trimmed.size.height
      break
    }

    hasSettled = true
  }
}


private extension UIImage {
  /// Crops away fully transparent margins.
  ///
  /// PackSim draws every wrapper into a square canvas, so a pack that is really
  /// about 1:1.9 arrives claiming to be 1:1 with air on either side. Taken at
  /// face value that squashes the wrapper into a square box — the pack renders
  /// small and centred, and the tear cuts across padding instead of across the
  /// wrapper. Trimming to the opaque bounds gives back both the true aspect
  /// ratio and a cut-out that lines up with the torn shapes.
  func trimmingTransparentEdges(threshold: UInt8 = 8) -> UIImage? {
    guard let cgImage else { return nil }

    let width = cgImage.width
    let height = cgImage.height
    guard width > 0, height > 0 else { return nil }

    var alpha = [UInt8](repeating: 0, count: width * height)
    guard
      let context = CGContext(
        data: &alpha,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
      )
    else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    var minX = width, minY = height, maxX = -1, maxY = -1
    for y in 0..<height {
      let row = y * width
      for x in 0..<width where alpha[row + x] > threshold {
        if x < minX { minX = x }
        if x > maxX { maxX = x }
        if y < minY { minY = y }
        if y > maxY { maxY = y }
      }
    }

    // Fully transparent, or already tight against its edges.
    guard maxX >= minX, maxY >= minY else { return nil }
    guard minX > 0 || minY > 0 || maxX < width - 1 || maxY < height - 1 else { return self }

    let crop = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    guard let cropped = cgImage.cropping(to: crop) else { return nil }

    return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
  }
}
