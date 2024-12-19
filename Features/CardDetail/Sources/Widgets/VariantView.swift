import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct VariantView<Card: MagicCard>: View {
  enum Action: Equatable {
    case didSelectCard(Card)
    case toggledFaceDirection(CardView<Card>.Model)
  }
  
  let title: String
  let subtitle: String
  let cards: IdentifiedArrayOf<CardView<Card>.Model>
  let send: (Action) -> Void
  
  var body: some View {
    Divider().safeAreaPadding(.leading, nil)
    
    VStack(alignment: .leading, spacing: 5.0) {
      Text(title).font(.headline)
      Text(subtitle).font(.caption).foregroundStyle(.secondary)
      
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 8.0) {
          ForEach(cards) { card in
            Button(
              action: {
//                send(.didSelectCard(card))
              }, label: {
                CardView(
                  model: card,
                  layoutConfiguration: CardView.LayoutConfiguration(
                    rotation: .portrait,
                    maxWidth: 170
                  )
                )
              }
            )
            .buttonStyle(.sinkableButtonStyle)
            .geometryGroup()
          }
        }
      }
      .frame(idealHeight: (170 / MagicCardImageRatio.widthToHeight.rawValue).rounded() + 21.0 + 18.0)
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
    cards: IdentifiedArrayOf<CardView<Card>.Model>,
    send: @escaping (Action) -> Void
  ) {
    self.title = title
    self.subtitle = subtitle
    self.cards = cards
    self.send = send
  }
}
