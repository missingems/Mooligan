import ComposableArchitecture
import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

struct VariantView: View {
  enum Action: Equatable {
    case didSelectCard(Card)
    case didShowCardAtIndex(Int)
  }
  
  let title: String
  let subtitle: String
  let cards: CardDataSource
  var isInitial: Bool
  let send: (Action) -> Void
  
  var body: some View {
    Divider().safeAreaPadding(.leading, nil)
    
    VStack(alignment: .leading, spacing: 5.0) {
      HStack {
        VStack(alignment: .leading) {
          Text(title).font(.headline)
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .shimmering(
              active: isInitial,
              gradient: Gradient(
                colors: [.secondary, .primary, .secondary]
              ),
              mode: .mask
            )
        }
        
        Spacer()
        
        if isInitial {
          ProgressView()
        }
      }
      
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 8.0) {
          ForEach(Array(zip(cards.cardDetails, cards.cardDetails.indices)), id: \.0.card.id) { value in
            let cardInfo = value.0
            let index = value.1
            
            Button(
              action: {
                send(.didSelectCard(cardInfo.card))
              }, label: {
                CardView(
                  displayableCard: cardInfo.displayableCardImage,
                  layoutConfiguration: CardView.LayoutConfiguration(
                    rotation: .portrait,
                    maxWidth: 170
                  ),
                  priceVisibility: .displaySet(
                    cardInfo.card.setName,
                    usdFoil: cardInfo.card.prices.usdFoil,
                    usd: cardInfo.card.prices.usd
                  )
                )
                .frame(maxWidth: 170.0)
              }
            )
            .buttonStyle(.sinkableButtonStyle)
            .task {
              send(.didShowCardAtIndex(index))
            }
          }
        }
      }
      .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
      .padding(.top, 3.0)
      .scrollClipDisabled(true)
    }
    .safeAreaPadding(.horizontal, nil)
    .padding(.vertical, 13.0)
  }
  
  init?(
    title: String,
    subtitle: String,
    cards: CardDataSource,
    isInitial: Bool,
    send: @escaping (Action) -> Void
  ) {
    self.title = title
    self.subtitle = subtitle
    self.cards = cards
    self.isInitial = isInitial
    self.send = send
  }
}
