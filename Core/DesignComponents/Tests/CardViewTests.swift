@testable import DesignComponents
import CoreGraphics
import Foundation
import Networking
import Testing

/// Grids mark `CardView` `.equatable()`, so its `==` decides whether a card is drawn again at all.
@MainActor struct CardViewTests {
  private let card = DisplayableCardImage.single(
    displayingImageURL: URL(string: "https://cards.scryfall.io/normal/front/a/b/ab12.jpg")!,
    id: "ab12"
  )
  private let layout = CardLayoutConfiguration(rotation: .portrait, maxWidth: 160)

  private func view(
    isFoil: Bool = false,
    intensity: Double = 1,
    downsampleWidth: CGFloat? = nil
  ) throws -> CardView<CardSurface> {
    try #require(
      CardView(
        displayableCard: card,
        layoutConfiguration: layout,
        surface: CardSurface(isFoil: isFoil, intensity: intensity),
        priceVisibility: .hidden,
        downsampleWidth: downsampleWidth
      )
    )
  }

  private func viewWithoutASurface(send: ((CardView<EmptyCardSurface>.Action) -> Void)? = nil) throws -> CardView<EmptyCardSurface> {
    try #require(
      CardView(displayableCard: card, layoutConfiguration: layout, priceVisibility: .hidden, send: send)
    )
  }

  @Test func viewsBuiltAlike_shouldBeEqual() throws {
    let first = try view(isFoil: true, intensity: 0.5, downsampleWidth: 31.5)
    let second = try view(isFoil: true, intensity: 0.5, downsampleWidth: 31.5)

    #expect(first == second)
  }

  /// Left out of the comparison, a surface's fade would stay at whatever it was when the card was
  /// first built.
  @Test func viewsDifferingOnlyInSurfaceIntensity_shouldNotBeEqual() throws {
    let faded = try view(intensity: 0)
    let lit = try view(intensity: 1)

    #expect(faded != lit)
  }

  @Test func viewsDifferingOnlyInFoil_shouldNotBeEqual() throws {
    let foil = try view(isFoil: true)
    let sheen = try view(isFoil: false)

    #expect(foil != sheen)
  }

  @Test func viewsDifferingOnlyInDownsampleWidth_shouldNotBeEqual() throws {
    let thumbnail = try view(downsampleWidth: 31.5)
    let larger = try view(downsampleWidth: 63)
    let fullSize = try view(downsampleWidth: nil)

    #expect(thumbnail != larger)
    #expect(thumbnail != fullSize)
  }

  /// `send` only reports a tap to a store that outlives the comparison, and closures are never equal.
  @Test func viewsDifferingOnlyInTheirTapHandler_shouldBeEqual() throws {
    let silent = try viewWithoutASurface()
    let tappable = try viewWithoutASurface(send: { _ in })

    #expect(silent == tappable)
  }

  /// Every grid card is built this way, and an unequal one would draw every card again on every
  /// store write.
  @Test func theInitialiserWithoutASurface_shouldBuildEqualViews() throws {
    let first = try viewWithoutASurface()
    let second = try viewWithoutASurface()

    #expect(first == second)
  }

  @Test func theInitialiserWithoutASurface_shouldMatchOneGivenAnEmptySurface() throws {
    let implicit = try viewWithoutASurface()
    let explicit = try #require(
      CardView(
        displayableCard: card,
        layoutConfiguration: layout,
        surface: EmptyCardSurface(),
        priceVisibility: .hidden
      )
    )

    #expect(implicit == explicit)
  }

  @Test func withoutACard_thereShouldBeNoView() {
    let missing: CardView<EmptyCardSurface>? = CardView(
      displayableCard: nil,
      layoutConfiguration: layout,
      priceVisibility: .hidden
    )

    #expect(missing == nil)
  }
}
