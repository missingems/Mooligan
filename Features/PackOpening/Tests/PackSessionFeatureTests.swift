@testable import PackOpening
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct PackSessionFeatureTests {
  private var product: PackProduct {
    PackProduct(set: MockGameSetRequestClient.mockSets[0], kind: .play)
  }

  private func makeStore(
    client: any BoosterPackClient = MockBoosterPackClient()
  ) -> TestStoreOf<PackSessionFeature> {
    TestStore(initialState: PackSessionFeature.State(product: product)) {
      PackSessionFeature()
    } withDependencies: {
      $0.boosterPackClient = client
      $0.packImagePrefetcher = ImmediatePackImagePrefetcher()
      $0.uuid = .incrementing
      $0.continuousClock = ImmediateClock()
    }
  }

  @Test func whenPreparing_shouldRollAndDownloadBeforeUnsealing() async {
    let store = makeStore()
    store.exhaustivity = .off(showSkippedAssertions: false)

    await store.send(.task)
    await store.skipReceivedActions()

    #expect(store.state.phase == .sealed)
    #expect(store.state.readiness == 1)
    #expect(store.state.pack?.cards.count == product.kind.cardCount)
    // Nothing is on screen until the art is in hand, which is the point of the
    // preparing phase.
    #expect(store.state.revealOrder.count == product.kind.cardCount)
  }

  @Test func whenRollingFails_shouldOfferRetry() async {
    let store = makeStore(client: FailingBoosterPackClient())
    store.exhaustivity = .off(showSkippedAssertions: false)

    await store.send(.task)
    await store.skipReceivedActions()

    guard case .failed = store.state.phase else {
      Issue.record("expected a failed phase, got \(store.state.phase)")
      return
    }
  }

  @Test func whenTearing_shouldReachTheReveal() async {
    let store = makeStore()
    store.exhaustivity = .off(showSkippedAssertions: false)

    await store.send(.task)
    await store.skipReceivedActions()

    await store.send(.tearCompleted)
    await store.skipReceivedActions()

    #expect(store.state.phase == .revealing)
  }

  @Test func whenCardsAreDealt_shouldTrackTheHighWaterMark() async {
    let store = makeStore()
    store.exhaustivity = .off(showSkippedAssertions: false)

    await store.send(.task)
    await store.skipReceivedActions()
    await store.send(.tearCompleted)
    await store.skipReceivedActions()

    await store.send(.revealed(upTo: 4))
    #expect(store.state.revealedCount == 4)

    // Rewinding walks the stack back but not what has been seen.
    await store.send(.revealed(upTo: 2))
    #expect(store.state.revealedCount == 4)
  }

  @Test func whenACardIsTapped_shouldPushItOverThePack() async {
    let store = makeStore()
    store.exhaustivity = .off(showSkippedAssertions: false)

    await store.send(.task)
    await store.skipReceivedActions()

    guard let pack = store.state.pack, let first = pack.cards.first else {
      Issue.record("no pack was rolled")
      return
    }

    await store.send(.didSelectCard(first))

    // Pushed onto the session's own stack rather than dismissing it: the pack
    // has to still be there to come back to.
    #expect(store.state.path.count == 1)
    #expect(store.state.phase == .sealed)
  }

  @Test func packImageURLs_shouldCoverEveryCard() async throws {
    let pack = try await MockBoosterPackClient().open(product: product, seed: UUID(0))
    #expect(pack.imageURLs.count == pack.cards.count)
  }
}

private struct FailingBoosterPackClient: BoosterPackClient {
  struct Failure: Error, LocalizedError {
    var errorDescription: String? { "no packs left" }
  }

  func products() async throws -> [PackProduct] { throw Failure() }
  func open(product: PackProduct, seed: UUID) async throws -> BoosterPack { throw Failure() }
}
