import DesignComponents
import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  var store: StoreOf<CardScannerFeature>
  
  public var body: some View {
    OCRView { [store] result in
      store.send(.didScan(result))
    }
  }
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
}
