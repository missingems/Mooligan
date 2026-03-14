import DesignComponents
import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  @Bindable var store: StoreOf<CardScannerFeature>
  
  public var body: some View {
    OCRView(result: $store.scannedResult)
  }
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
}
