//
//  VariantGalleryView.swift
//  CardDetail
//
//  Created by Jun on 22/3/25.
//

import DesignComponents
import SwiftUI
import Networking

struct VariantGalleryView: View {
  var cardDataSource: CardDataSource
  
  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(cardDataSource.cardDetails, id: \.card.id) { detail in
          content(card: detail)
            .containerRelativeFrame(.horizontal)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.viewAligned)
  }
  
  @ViewBuilder func content(card: CardInfo) -> some View {
    CardView(
      displayableCard: card.displayableCardImage,
      layoutConfiguration: .init(rotation: .portrait, maxWidth: 320),
      priceVisibility: .hidden
    )
  }
}
