import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

enum EntryPoint: Equatable, Sendable {
  case query
  case set(MTGSet)
}

struct RootView: View {
  private let store: StoreOf<CardDetailFeature>
  
  var body: some View {
    Text("")
  }
  
  init(store: StoreOf<CardDetailFeature>) {
    self.store = store
  }
}
