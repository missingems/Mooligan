import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  @Bindable var store: StoreOf<QueryFeature>
  
  public var body: some View {
    QueryView(store: store)
  }
  
  public init(store: StoreOf<QueryFeature>) {
    self.store = store
  }
}
