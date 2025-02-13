import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  @Bindable var store: StoreOf<Feature>
  
  public var body: some View {
    QueryView(store: store)
  }
  
  public init(store: StoreOf<Feature>) {
    self.store = store
  }
}
