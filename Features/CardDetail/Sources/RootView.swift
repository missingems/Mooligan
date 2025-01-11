import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct RootView: View {
  private let store: StoreOf<CardDetailFeature>
  
  public var body: some View {
    CardDetailView(store: store)
  }
  
  public init(store: StoreOf<CardDetailFeature>) {
    self.store = store
  }
}
