import SwiftUI

/// Identifies one rendering of `IconLazyImage`: the same icon in a different tint, at a different
/// raster size, or a different icon entirely is a different request, and gets its own entry in
/// `IconBitmapCache`.
struct IconRequest: Equatable {
  let url: URL?
  let tint: Color.Resolved
  /// The square box, in points, the icon is rasterized into.
  var pointSize: CGFloat = IconLazyImage.defaultRasterSize
}
