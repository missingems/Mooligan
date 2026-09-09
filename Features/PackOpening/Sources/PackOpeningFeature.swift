import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit

/// The shelf: what the machine stocks, and which pack the player is opening.
@Reducer public struct PackOpeningFeature: Sendable {
  @Dependency(\.boosterPackClient) private var client
  @Dependency(\.uuid) private var uuid
  @Dependency(\.continuousClock) private var clock

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      // The search field and the kind filter are pure state: `visibleProducts`
      // re-derives the shelf, so there is nothing to do here.
      case .binding:
        return .none

      case .task:
        guard state.mode.isLoading else { return .none }
        return loadProducts()

      case .retry:
        state.mode = .loading
        return loadProducts()

      case let .productsLoaded(products):
        state.mode = .data(IdentifiedArrayOf(uniqueElements: products))
        return .none

      case let .loadFailed(message):
        state.mode = .error(message)
        return .none

      case let .didSelectProduct(product):
        guard state.dispensingProductID == nil else { return .none }
        state.dispensingProductID = product.id

        return .run { send in
          // The machine takes a beat to drop the pack. Rolling inside that beat
          // means the tear screen never opens onto a spinner.
          async let pack = client.open(product: product, seed: uuid())
          async let delay: Void = try clock.sleep(for: .milliseconds(320))

          do {
            let rolled = try await pack
            _ = try? await delay
            await send(.packRolled(rolled))
          } catch {
            _ = try? await delay
            await send(.openFailed(error.localizedDescription))
          }
        }

      case let .packRolled(pack):
        state.dispensingProductID = nil
        state.session = PackSessionFeature.State(pack: pack)
        return .none

      case let .openFailed(message):
        state.dispensingProductID = nil
        state.alert = AlertState {
          TextState("Couldn't open that pack")
        } actions: {
          ButtonState(role: .cancel) { TextState("OK") }
        } message: {
          TextState(message)
        }
        return .none

      case .alert:
        return .none

      case .session(.presented(.delegate(.openAnother))):
        guard let product = state.session?.pack.product else { return .none }
        state.session = nil
        return .send(.didSelectProduct(product))

      case .session(.presented(.delegate(.finished))):
        state.session = nil
        return .none

      case .session:
        return .none
      }
    }
    .ifLet(\.$session, action: \.session) {
      PackSessionFeature()
    }
    .ifLet(\.$alert, action: \.alert)
  }

  private func loadProducts() -> Effect<Action> {
    .run { send in
      let products = try await client.products()
      await send(.productsLoaded(products))
    } catch: { error, send in
      await send(.loadFailed(error.localizedDescription))
    }
    .cancellable(id: CancelID.load, cancelInFlight: true)
  }

  private enum CancelID { case load }
}

public extension PackOpeningFeature {
  @ObservableState struct State: Equatable {
    var mode: Mode = .loading
    var query = ""
    var kindFilter: BoosterPackKind?

    /// Set while the machine plays its dispense animation, so the slot can
    /// animate and a second tap is ignored.
    var dispensingProductID: PackProduct.ID?

    @Presents var session: PackSessionFeature.State?
    @Presents var alert: AlertState<Action.Alert>?

    public init() {}

    /// Shelf contents after the search field and the pack-kind filter.
    var visibleProducts: [PackProduct] {
      let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

      return mode.products.filter { product in
        if let kindFilter, product.kind != kindFilter { return false }
        guard trimmed.isEmpty == false else { return true }

        return product.set.name.localizedCaseInsensitiveContains(trimmed)
          || product.setCode.localizedCaseInsensitiveContains(trimmed)
      }
    }
  }

  // `@Reducer` only applies this to an `Action` nested directly in the reducer;
  // ours lives in an extension, and the `\.session` / `\.alert` scopes need it.
  @CasePathable enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case task
    case retry
    case productsLoaded([PackProduct])
    case loadFailed(String)
    case didSelectProduct(PackProduct)
    case packRolled(BoosterPack)
    case openFailed(String)
    case session(PresentationAction<PackSessionFeature.Action>)
    case alert(PresentationAction<Alert>)

    public enum Alert: Equatable {}
  }
}

public extension PackOpeningFeature.State {
  enum Mode: Equatable {
    case loading
    case data(IdentifiedArrayOf<PackProduct>)
    case error(String)

    var isLoading: Bool {
      if case .loading = self { return true }
      return false
    }

    var products: [PackProduct] {
      if case let .data(value) = self { return Array(value) }
      return []
    }
  }
}

