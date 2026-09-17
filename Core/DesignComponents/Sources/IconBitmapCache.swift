import SwiftUI
import UIKit

/// The rasterized bitmap for each `IconRequest`, rendered once by `IconLazyImage` and reused for
/// every later reappearance of that icon (a set row scrolled back into view, a screen revisited)
/// instead of asking SwiftUI to mask and composite the vector icon again.
///
/// `NSCache` is documented thread-safe, so this is reachable from any isolation — including a
/// view's plain, non-isolated `init`, to show an already-rendered icon on its very first frame.
enum IconBitmapCache {
  nonisolated(unsafe) private static let images: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.countLimit = 128
    return cache
  }()

  static func image(for request: IconRequest) -> UIImage? {
    guard let key = key(for: request) else { return nil }
    return images.object(forKey: key as NSString)
  }

  static func insert(_ image: UIImage, for request: IconRequest) {
    guard let key = key(for: request) else { return }
    images.setObject(image, forKey: key as NSString)
  }

  /// `nil` for a request without a URL, which is never cached.
  static func key(for request: IconRequest) -> String? {
    guard let url = request.url else { return nil }
    let tint = request.tint
    return "\(url.absoluteString)#\(tint.red),\(tint.green),\(tint.blue),\(tint.opacity)@\(request.pointSize)"
  }
}
