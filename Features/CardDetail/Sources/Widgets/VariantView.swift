import DesignComponents
import Networking
import SwiftUI

struct VariantView: View {
  enum Action: Sendable, Equatable {
    case didSelectCardAtIndex(Int)
  }
  
  let title: String
  let subtitle: String
  let cards: [any MagicCard]
  let send: (Action) -> Void
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(title).font(.headline)
      Text(subtitle).font(.caption).foregroundStyle(.secondary)
      
      ScrollView(
        .horizontal,
        showsIndicators: false
      ) {
        HStack(spacing: 13.0) {
          ForEach(cards.indices, id: \.self) { index in
            Button(
              action: {
                send(.didSelectCardAtIndex(index))
              }, label: {
                CardView(
                  card: cards[index],
                  layoutConfiguration: .fixedWidth(150.0)
                )
              }
            )
            .buttonStyle(.sinkableButtonStyle)
          }
        }
      }
    }
    .scrollClipDisabled()
    .safeAreaPadding(.horizontal, nil)
  }
  
  init?(
    title: String,
    subtitle: String,
    cards: [any MagicCard]?,
    send: @escaping (Action) -> Void
  ) {
    guard let cards else { return nil }
    
    self.title = title
    self.subtitle = subtitle
    self.cards = cards
    self.send = send
  }
}

#Preview {
  VariantView(
    title: "Prints",
    subtitle: "4 cards",
    cards: [
      MagicCardFixtures.split.value,
      MagicCardFixtures.split.value,
      MagicCardFixtures.split.value,
      MagicCardFixtures.split.value
    ]
  ) { _ in }
}
