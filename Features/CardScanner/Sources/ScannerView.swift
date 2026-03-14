import ComposableArchitecture
import DesignComponents
import SwiftUI

public struct ScannerView: View {
  @Bindable private var store: StoreOf<CardScannerFeature>
  
  public var body: some View {
    OCRView(result: $store.scannedResult)
  }
}
