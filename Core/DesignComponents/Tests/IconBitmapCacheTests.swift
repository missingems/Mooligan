@testable import DesignComponents
import SwiftUI
import Testing

/// `IconBitmapCache` is process-wide state, and Swift Testing runs these tests concurrently, so each
/// test uses its own URL to avoid one test's insert racing another's read of the same key.
struct IconBitmapCacheTests {
  private func request(_ url: URL, _ color: Color) -> IconRequest {
    IconRequest(url: url, tint: color.resolve(in: EnvironmentValues()))
  }

  @Test func aStoredBitmapShouldBeReadBackForTheSameRequest() {
    let url = URL(string: "https://img.scryfall.com/sets/woe.svg")!
    let image = UIImage()
    IconBitmapCache.insert(image, for: request(url, .red))

    #expect(IconBitmapCache.image(for: request(url, .red)) === image)
  }

  /// The same icon tinted two different ways (a set's icon shown once in accent colour, once in
  /// `.secondary`, say) must not collide on one cache entry.
  @Test func theSameIconInADifferentTintShouldNotShareAnEntry() {
    let url = URL(string: "https://img.scryfall.com/sets/mkm.svg")!
    IconBitmapCache.insert(UIImage(), for: request(url, .red))

    #expect(IconBitmapCache.image(for: request(url, .blue)) == nil)
  }

  /// The booster wrapper draws a set icon at a few hundred points, the set list at 34; the large
  /// raster must not be served to the list, nor the small one blown up on the wrapper.
  @Test func theSameIconAtADifferentRasterSizeShouldNotShareAnEntry() {
    let url = URL(string: "https://img.scryfall.com/sets/fin.svg")!
    let small = IconRequest(url: url, tint: Color.red.resolve(in: EnvironmentValues()), pointSize: 48)
    let large = IconRequest(url: url, tint: Color.red.resolve(in: EnvironmentValues()), pointSize: 320)
    IconBitmapCache.insert(UIImage(), for: small)

    #expect(IconBitmapCache.image(for: large) == nil)
  }

  @Test func aRequestWithoutAURLShouldNeverBeStoredOrRead() {
    let request = IconRequest(url: nil, tint: Color.red.resolve(in: EnvironmentValues()))
    IconBitmapCache.insert(UIImage(), for: request)

    #expect(IconBitmapCache.image(for: request) == nil)
  }
}
