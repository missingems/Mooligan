@testable import PackOpening
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct PackOpeningFeatureTests {
  private func makeStore() -> TestStoreOf<PackOpeningFeature> {
    TestStore(initialState: PackOpeningFeature.State()) {
      PackOpeningFeature()
    } withDependencies: {
      $0.boosterPackClient = MockBoosterPackClient()
      $0.uuid = .incrementing
      $0.continuousClock = ImmediateClock()
    }
  }

  @Test func whenTaskRuns_shouldStockTheMachine() async {
    let store = makeStore()
    let products = try? await MockBoosterPackClient().products()

    await store.send(.task)
    await store.receive(.productsLoaded(products ?? [])) {
      $0.mode = .data(IdentifiedArrayOf(uniqueElements: products ?? []))
    }
  }

  @Test func whenAProductIsSelected_shouldRollAPackAndOpenTheSession() async {
    let store = makeStore()
    store.exhaustivity = .off(showSkippedAssertions: false)

    await store.send(.task)
    await store.skipReceivedActions()

    guard let product = store.state.mode.products.first else {
      Issue.record("machine was not stocked")
      return
    }

    await store.send(.didSelectProduct(product)) {
      $0.dispensingProductID = product.id
    }
    await store.receive(\.packRolled)

    #expect(store.state.dispensingProductID == nil)
    #expect(store.state.session?.pack.product == product)
    #expect(store.state.session?.pack.cards.count == product.kind.cardCount)
    #expect(store.state.session?.phase == .sealed)
  }

  @Test func whenLoadingFails_shouldOfferRetry() async {
    let store = TestStore(initialState: PackOpeningFeature.State()) {
      PackOpeningFeature()
    } withDependencies: {
      $0.boosterPackClient = FailingBoosterPackClient()
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.task)
    await store.receive(\.loadFailed) {
      $0.mode = .error(PackOpeningTestError.offline.localizedDescription)
    }
  }

  @Test func whenFiltering_shouldNarrowTheShelf() async {
    let store = makeStore()
    store.exhaustivity = .off

    await store.send(.task)
    await store.skipReceivedActions()

    let allCount = store.state.visibleProducts.count
    await store.send(.binding(.set(\.kindFilter, .collector)))

    #expect(store.state.visibleProducts.count < allCount)
    #expect(store.state.visibleProducts.allSatisfy { $0.kind == .collector })
  }
}

@MainActor struct PackSessionFeatureTests {
  private func makePack() async throws -> BoosterPack {
    let client = MockBoosterPackClient()
    let product = try #require(try await client.products().first)
    return try await client.open(product: product, seed: UUID(0))
  }

  @Test func tearingThenRevealing_shouldEndOnTheSummary() async throws {
    let pack = try await makePack()

    let store = TestStore(initialState: PackSessionFeature.State(pack: pack)) {
      PackSessionFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.tearCompleted) { $0.phase = .opening }
    await store.receive(.wrapperCleared) { $0.phase = .revealing }

    for index in 1...pack.cards.count {
      await store.send(.revealNext) { $0.revealedCount = index }
    }

    await store.receive(.showSummary) { $0.phase = .summary }
  }

  @Test func revealAll_shouldJumpStraightToTheSummary() async throws {
    let pack = try await makePack()

    let store = TestStore(initialState: PackSessionFeature.State(pack: pack)) {
      PackSessionFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.tearCompleted) { $0.phase = .opening }
    await store.receive(.wrapperCleared) { $0.phase = .revealing }

    await store.send(.revealAll) { $0.revealedCount = pack.cards.count }
    await store.receive(.showSummary) { $0.phase = .summary }
  }

  @Test func headlinersAreRevealedLast() async throws {
    let pack = try await makePack()
    let order = pack.revealOrder

    let firstHeadliner = order.firstIndex { $0.slot.isHeadliner }
    let lastFiller = order.lastIndex { $0.excitement == 0 }

    if let firstHeadliner, let lastFiller {
      #expect(lastFiller < firstHeadliner)
    }
  }
}

// MARK: - Doubles

private enum PackOpeningTestError: Error, LocalizedError {
  case offline

  var errorDescription: String? { "Offline" }
}

private struct FailingBoosterPackClient: BoosterPackClient {
  func products() async throws -> [PackProduct] {
    throw PackOpeningTestError.offline
  }

  func open(product: PackProduct, seed: UUID) async throws -> BoosterPack {
    throw PackOpeningTestError.offline
  }
}
