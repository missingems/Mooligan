import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  @Bindable var store: StoreOf<Feature>
  let namespace: Namespace.ID
  
  public var body: some View {
    QueryView(store: store, namespace: namespace)
  }
  
  public init(store: StoreOf<Feature>, namespace: Namespace.ID) {
    self.store = store
    self.namespace = namespace
  }
}
