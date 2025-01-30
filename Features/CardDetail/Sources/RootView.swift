import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct RootView: View {
  private let store: StoreOf<CardDetailFeature>
  private let namespace: Namespace.ID
  
  public var body: some View {
    CardDetailView(store: store, namespace: namespace)
  }
  
  public init(store: StoreOf<CardDetailFeature>, namespace: Namespace.ID) {
    self.store = store
    self.namespace = namespace
  }
}
