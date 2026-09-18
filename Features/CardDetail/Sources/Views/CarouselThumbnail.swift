import DesignComponents
import Nuke
import NukeUI
import SwiftUI

struct CarouselThumbnail: View {
  let url: URL
  let width: CGFloat

  var body: some View {
    LazyImage(
      request: ImageRequest(
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
    ) { state in
      Color.primary.opacity(0.116).overlay {
        if let image = state.image {
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        }
      }
    }
    .frame(width: width, height: (width * 3 / 4).rounded())
    .clipShape(.rect(cornerRadius: 4.0, style: .continuous))
  }
}
