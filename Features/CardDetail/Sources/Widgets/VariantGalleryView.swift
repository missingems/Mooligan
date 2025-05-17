//
//  VariantGalleryView.swift
//  CardDetail
//
//  Created by Jun on 22/3/25.
//

import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking

public struct VariantGalleryView: View {
  public let store: StoreOf<VariantGalleryFeature>
  private let zoomNamespace: Namespace.ID?
  
  public var body: some View {
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(store.cardDataSource.cardDetails, id: \.card.id) { detail in
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
      priceVisibility: .hidden,
      zoomNamespace: zoomNamespace
    )
  }
  
  public init(store: StoreOf<VariantGalleryFeature>, zoomNamespace: Namespace.ID?) {
    self.store = store
    self.zoomNamespace = zoomNamespace
  }
}
