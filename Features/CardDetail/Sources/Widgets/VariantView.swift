import DesignComponents
import Networking
import SwiftUI

struct VariantView<Card: MagicCard>: View {
  enum Action: Sendable, Equatable {
    case didSelectCard(Card)
  }
  
  let title: String
  let subtitle: String
  let cards: [Card]
  let send: (Action) -> Void
  
  var body: some View {
//    Divider().safeAreaPadding(.leading, nil)
    
    VStack(alignment: .leading, spacing: 5.0) {
      Text(title).font(.headline)
      Text(subtitle).font(.caption).foregroundStyle(.secondary)
      
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 8.0) {
          ForEach(cards) { card in
            Button(
              action: {
                send(.didSelectCard(card))
              }, label: {
                CardView(
                  card: card,
                  layoutConfiguration: .fixedWidth(150.0)
                )
              }
            )
            .buttonStyle(.sinkableButtonStyle)
            .scrollTransition { view, phase in
              switch phase {
              case .topLeading:
                view.opacity(0).offset(x: 150, y: 0).scaleEffect(0.9).blur(radius: 3)
                
              case .identity:
                view.opacity(1).offset(x: 0, y: 0).scaleEffect(1).blur(radius: 0)
                
              case .bottomTrailing:
                view.opacity(1).offset(x: 0, y: 0).scaleEffect(1).blur(radius: 0)
              }
            }
          }
        }
      }
      .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
      .padding(.top, 3.0)
      .scrollClipDisabled(true)
    }
//    .safeAreaPadding(.horizontal, nil)
    .padding(.vertical, 13.0)
  }
  
  init?(
    title: String,
    subtitle: String,
    cards: [Card]?,
    send: @escaping (Action) -> Void
  ) {
    guard let cards else { return nil }
    
    self.title = title
    self.subtitle = subtitle
    self.cards = cards
    self.send = send
  }
}
