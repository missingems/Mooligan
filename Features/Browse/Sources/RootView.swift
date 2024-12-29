import ComposableArchitecture
import ScryfallKit
import SwiftUI

public struct RootView: View {
  @Bindable public var store: StoreOf<Feature>
  
  public var body: some View {
    SetsView(store: store)
      .navigationTitle(store.title)
  }
  
  public init(store: StoreOf<Feature>) {
    self.store = store
  }
}
