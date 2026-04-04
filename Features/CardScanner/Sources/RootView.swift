import DesignComponents
import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  let store: StoreOf<CardScannerFeature>
  
  public var body: some View {
    NavigationView {
      ZStack(alignment: .bottom) {
        OCRView { result in
          store.send(.didScan(result))
        }
        .ignoresSafeArea(.all)
        
        HStack {
          Button(action: {
            print("Blank circle pressed")
          }) {
            ZStack {
              Circle()
            }
            .frame(width: 83, height: 83)
          }
          .padding(.all, 6)
          .glassEffect(.regular.interactive(), in: .circle)
        }
        .padding(.bottom, 20)
      }
      .task {
        store.send(.syncCardImageHashDatabase)
      }
    }
  }
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
}
