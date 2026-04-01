import DesignComponents
import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  let store: StoreOf<CardScannerFeature>
  
  public var body: some View {
    NavigationView {
      VStack(spacing: 16.0) {
        OCRView { result in
          store.send(.didScan(result))
        }
        .ignoresSafeArea(.all)
        .background(.gray)
        .clipShape(RoundedRectangle(cornerRadius: 24.0))
        
        if let cardDetails = store.dataSource?.cardDetails, !cardDetails.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8.0) {
              ForEach(Array(zip(cardDetails, cardDetails.indices)), id: \.0.card.id) { value in
                let cardInfo = value.0
                let index = value.1
                
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
                .onAppear {
                  store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
                }
              }
            }
            .padding(.horizontal, 16.0)
          }
          .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
          .padding(.top, 3.0)
          .padding(.bottom, 16.0)
          .scrollClipDisabled(true)
          .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
}

