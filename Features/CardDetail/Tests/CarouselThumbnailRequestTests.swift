@testable import CardDetail
import DesignComponents
import Foundation
import Nuke
import Testing

/// The strip's tiles are 44pt and the lens draws them half again as large, from one request built
/// the same whatever the tile's size, so every card is fetched and decoded once.
struct CarouselThumbnailRequestTests {
  private let url = URL(string: "https://cards.scryfall.io/normal/front/a/b/ab.jpg")!

  private func identifiers(of request: ImageRequest) -> [String] {
    request.processors.map { $0.identifier }
  }

  @Test func whenBuilt_shouldAskForTheCardsImage() {
    #expect(ImageRequest.carouselThumbnail(url).url == url)
  }

  @Test func whenBuilt_shouldCropTheTightArtBoxAndThenResizeToAFixedWidth() {
    #expect(identifiers(of: .carouselThumbnail(url)) == [
      ArtCropImageProcessor(artBox: CGRect(x: 0.22, y: 0.17, width: 0.56, height: 0.3)).identifier,
      ImageProcessors.Resize(width: 260.0).identifier,
    ])
  }

  @Test func whenCropping_shouldNotShareTheBackdropsCrop() {
    // The backdrop runs the standard art box down to the type line, which a borderless card prints
    // over its own art.
    let crop = identifiers(of: .carouselThumbnail(url)).first

    #expect(crop != ArtCropImageProcessor().identifier)
  }
}
