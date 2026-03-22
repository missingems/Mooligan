import DesignComponents
import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  var store: StoreOf<CardScannerFeature>
  
  public var body: some View {
    ZStack(alignment: .bottom) {
      OCRView { [store] result in
        store.send(.didScan(result))
      }
      
      if let cardDetails = store.dataSource?.cardDetails {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(spacing: 8.0) {
            ForEach(Array(zip(cardDetails, cardDetails.indices)), id: \.0.card.id) { value in
              let cardInfo = value.0
              
              Button(
                action: {
                }, label: {
                  CardView(
                    displayableCard: cardInfo.displayableCardImage,
                    priceVisibility: .hidden,
                    shouldShowShadow: false
                  )
                }
              )
              .frame(width: 183)
              .buttonStyle(.sinkableButtonStyle)
            }
          }
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .padding(.top, 3.0)
        .scrollClipDisabled(true)
      }
    }
  }
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
}
