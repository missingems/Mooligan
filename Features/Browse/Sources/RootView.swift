import ComposableArchitecture
import ScryfallKit
import SwiftUI

public struct RootView: View {
  public var store: StoreOf<Feature>
  
  public var body: some View {
    let _ = Self._printChanges()
    SetsView(store: store)
  }
  
  public init(store: StoreOf<Feature>) {
    self.store = store
  }
}
