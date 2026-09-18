import Nuke
import NukeUI
import SwiftUI

struct CarouselThumbnail: View {
  let url: URL
  let width: CGFloat

  var body: some View {
    LazyImage(request: ImageRequest.carouselThumbnail(url)) { state in
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
