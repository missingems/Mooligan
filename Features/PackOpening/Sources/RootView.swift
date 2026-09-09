import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

/// Entry point for the pack simulator: the machine, plus the full-screen
/// opening session it presents.
public struct RootView: View {
  @Bindable var store: StoreOf<PackOpeningFeature>
  @Namespace private var dispenseNamespace

  public init(store: StoreOf<PackOpeningFeature>) {
    self.store = store
  }

  public var body: some View {
    PackShelfView(store: store, dispenseNamespace: dispenseNamespace)
      .task { store.send(.task) }
      .fullScreenCover(
        item: $store.scope(state: \.session, action: \.session)
      ) { sessionStore in
        PackSessionView(store: sessionStore)
          .navigationTransition(
            .zoom(sourceID: sessionStore.pack.product.id, in: dispenseNamespace)
          )
      }
      .alert($store.scope(state: \.alert, action: \.alert))
      .accessibilityIdentifier("packOpening.root")
  }
}
