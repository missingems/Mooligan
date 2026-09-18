import DesignComponents
import Foundation
import Nuke

extension ImageRequest {
  static func carouselThumbnail(_ url: URL) -> ImageRequest {
    ImageRequest(
      url: url,
      processors: [
        // Tighter than the backdrop's crop and 4:3 on a normal card's pixels. The standard art box
        // runs down to the type line, which a borderless card prints over its own art, so the
        // strip was showing "Legendary Planeswalker — Ajani" along the bottom of the tile.
        ArtCropImageProcessor(artBox: CGRect(x: 0.22, y: 0.17, width: 0.56, height: 0.3)),
        // A fixed width, not the tile's: the lens draws the same cards half again as large, and a
        // size-derived one would give it its own cache entry and a second decode of every card.
        ImageProcessors.Resize(width: 260.0),
      ]
    )
  }
}
