import DesignComponents
import Nuke
import NukeUI
import SwiftUI

struct LandingBackdrop: View {
  let scrub: CarouselScrub?

  var body: some View {
    if let url = scrub?.landingBackdrop {
      LazyImage(request: ImageRequest(url: url, processors: [ArtCropImageProcessor()])) { state in
        if let image = state.image {
          image
            .resizable()
            .blur(radius: 89, opaque: true)
        }
      }
      .allowsHitTesting(false)
      .ignoresSafeArea()
    }
  }
}
