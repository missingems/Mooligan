import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct RootView: View {
  private let store: StoreOf<CardDetailFeature>
  private let zoomNamespace: Namespace.ID
  
  public var body: some View {
    CardDetailView(store: store, zoomNamespace: zoomNamespace)
  }
  
  public init(store: StoreOf<CardDetailFeature>, zoomNamespace: Namespace.ID) {
    self.store = store
    self.zoomNamespace = zoomNamespace
  }
}
