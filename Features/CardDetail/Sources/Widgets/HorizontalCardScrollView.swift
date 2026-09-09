import ComposableArchitecture
import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

struct HorizontalCardScrollView: View, Equatable {
  /// Compared on what it draws, not on `send`, which is a closure and so never
  /// equal. A row of card images is expensive to rebuild and none of these
  /// rows changes after its own request lands.
  nonisolated static func == (lhs: HorizontalCardScrollView, rhs: HorizontalCardScrollView) -> Bool {
    lhs.title == rhs.title
      && lhs.subtitle == rhs.subtitle
      && lhs.isInitial == rhs.isInitial
      && lhs.cards == rhs.cards
  }

  enum Action: Equatable {
    case didSelectCard(Card)
    case didShowCardAtIndex(Int)
  }
  
  private static let cardWidth: CGFloat = 183
  
  let title: String
  let subtitle: String
  let cards: CardDataSource
  var isInitial: Bool
  let send: (Action) -> Void
  
  var body: some View {
    VibrantDivider().safeAreaPadding(.leading, systemHorizontalMargin)
    
    VStack(alignment: .leading, spacing: 5.0) {
      HStack {
        VStack(alignment: .leading, spacing: 5.0) {
          Text(title).font(.headline)
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        Spacer()
        
        if isInitial {
          ProgressView()
        }
      }
      
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 8.0) {
          ForEach(cards.cardDetails) { cardInfo in
            Button(
              action: { send(.didSelectCard(cardInfo.card)) },
              label: {
                CardView(
                  displayableCard: cardInfo.displayableCardImage,
                  layoutConfiguration: CardView.LayoutConfiguration(
                    rotation: .portrait,
                    maxWidth: Self.cardWidth
                  ),
                  priceVisibility: .displaySet(
                    cardInfo.card.setName,
                    usdFoil: cardInfo.card.prices.usdFoil,
                    usd: cardInfo.card.prices.usd
                  ),
                  shadowConfiguration: nil
                )
                .frame(width: Self.cardWidth)
              }
            )
            .buttonStyle(.sinkableButtonStyle)
          }
        }
      }
      .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
      .padding(.top, 3.0)
      .scrollClipDisabled(true)
    }
    .safeAreaPadding(.horizontal, systemHorizontalMargin)
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
