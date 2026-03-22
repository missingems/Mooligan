import SwiftUI
import CardScanner
import ComposableArchitecture
import DesignComponents

@main
struct RunnerApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        RootView(
          store: Store(
            initialState: CardScannerFeature.State(
              scannedResult: OCRCardScannedResult(title: "", set: nil, code: nil)
            )
          ) {
            CardScannerFeature()
          }
        )
      }
    }
  }
}
