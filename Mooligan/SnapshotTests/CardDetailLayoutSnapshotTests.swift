@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

/// The card detail page for every card layout the table and card image handle, rendered inside
/// the real pager so the page is sized exactly as it is in the app.
///
/// Fixtures are real Scryfall responses with the image URLs replaced, so no image loads.
@MainActor
@Suite(.serialized)
struct CardDetailLayoutSnapshotTests {
  private static let width: CGFloat = 402.0
  private static let height: CGFloat = 1_500.0

  static func card(_ fixture: String) throws -> Card {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appending(path: "Fixtures/Cards/\(fixture).json")
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    var card = try decoder.decode(Card.self, from: Data(contentsOf: url))

    // Every image points at one local card image, so pages render a loaded card (no network,
    // no loading shimmer) and a landscape card's rotation is visible.
    let image = try cardImageURL().absoluteString
    let uris = Card.ImageUris(small: image, normal: image, large: image, png: image, artCrop: image, borderCrop: image)
    if card.imageUris != nil { card.imageUris = uris }
    card.cardFaces = card.cardFaces?.map { face in
      var face = face
      if face.imageUris != nil { face.imageUris = uris }
      return face
    }
    return card
  }

  /// A portrait card image with a marked top edge.
  private static func cardImageURL() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: "card-detail-layout-card.png")
    guard FileManager.default.fileExists(atPath: url.path()) == false else { return url }

    let size = CGSize(width: 488.0, height: 680.0)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    let png = UIGraphicsImageRenderer(size: size, format: format).pngData { context in
      UIColor(red: 0.36, green: 0.42, blue: 0.55, alpha: 1.0).setFill()
      context.fill(CGRect(origin: .zero, size: size))
      UIColor(red: 0.93, green: 0.78, blue: 0.36, alpha: 1.0).setFill()
      context.fill(CGRect(x: 0.0, y: 0.0, width: size.width, height: 96.0))
      UIColor.white.withAlphaComponent(0.8).setFill()
      context.fill(CGRect(x: 40.0, y: 140.0, width: size.width - 80.0, height: 300.0))
    }
    try png.write(to: url)
    return url
  }

  private func page(for card: Card) -> some View {
    let store = StoreOf<CardPagerFeature>(
      initialState: CardPagerFeature.State(
        cardDetails: [CardInfo(card: card)],
        initialSelectedCard: card,
        queryType: .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
      )
    ) {
      EmptyReducer<CardPagerFeature.State, CardPagerFeature.Action>()
    }
    return CardPagerView(store: store)
  }

  private func snapshot(_ fixture: String, testName: String = #function) async throws {
    await SnapshotWindow.acquire()
    defer { SnapshotWindow.release() }

    let card = try Self.card(fixture)
    let controller = UIHostingController(rootView: page(for: card))
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    window.frame = CGRect(x: 0.0, y: 0.0, width: Self.width, height: Self.height)
    window.overrideUserInterfaceStyle = .dark
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.view.frame = window.bounds
    try await Task.sleep(for: .seconds(2.0))

    assertSnapshot(
      of: controller.view,
      as: .image(drawHierarchyInKeyWindow: true, precision: 0.98, perceptualPrecision: 0.98),
      named: fixture,
      testName: testName
    )

    window.isHidden = true
    window.rootViewController = nil
  }

  @Test(arguments: [
    "normal", "planeswalker", "split", "aftermath", "room", "adventure", "prepare",
    "flip", "transform", "modalDfc", "battle",
  ])
  func cardDetailPage(_ fixture: String) async throws {
    try await snapshot(fixture)
  }
}
