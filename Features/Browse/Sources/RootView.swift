import ComposableArchitecture
import ScryfallKit
import SwiftUI

public struct RootView: View {
  public var store: StoreOf<BrowseFeature>
  public let namespace: Namespace.ID
  
  public var body: some View {
    SetsView(store: store, namespace: namespace)
  }
  
  public init(store: StoreOf<BrowseFeature>, namespace: Namespace.ID) {
    self.store = store
    self.namespace = namespace
  }
}
