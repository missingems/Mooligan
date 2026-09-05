import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct RootView: View {
  private let store: StoreOf<CardDetailFeature>
  
  public var body: some View {
    CardDetailView(store: store)
      .edgeScrims()
      .task(priority: .background) {
        store.send(.viewAppeared(initialAction: .fetchAdditionalInformation(card: store.content.card)))
      }
  }
  
  public init(store: StoreOf<CardDetailFeature>) {
    self.store = store
  }
}
