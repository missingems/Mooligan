import ComposableArchitecture
import ScryfallKit
import SwiftUI

public struct RootView: View {
  public var store: StoreOf<BrowseFeature>
  
  public var body: some View {
    SetsView(store: store)
  }
  
  public init(store: StoreOf<BrowseFeature>) {
    self.store = store
  }
}
