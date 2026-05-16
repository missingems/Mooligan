import ComposableArchitecture
import ScryfallKit
import SwiftUI

public struct RootView: View {
  public var store: StoreOf<BrowseFeature>
  public var zoomAnimation: Namespace.ID
  
  public var body: some View {
    SetsView(store: store, zoomAnimation: zoomAnimation)
  }
  
  public init(store: StoreOf<BrowseFeature>, zoomAnimation: Namespace.ID) {
    self.store = store
    self.zoomAnimation = zoomAnimation
  }
}
