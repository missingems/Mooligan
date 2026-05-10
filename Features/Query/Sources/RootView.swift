import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  @Bindable var store: StoreOf<QueryFeature>
  var zoomAnimation: Namespace.ID
  
  public var body: some View {
    QueryView(store: store, zoomAnimation: zoomAnimation)
  }
  
  public init(store: StoreOf<QueryFeature>, zoomAnimation: Namespace.ID) {
    self.store = store
    self.zoomAnimation = zoomAnimation
  }
}
