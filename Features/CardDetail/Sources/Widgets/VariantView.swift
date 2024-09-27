import DesignComponents
import Networking
import SwiftUI

struct VariantView: View {
  enum Action: Sendable, Equatable {
    case didSelectCardAtIndex(Int)
  }
  
  let title: String
  let cards: [any MagicCard]
  let send: (Action) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(title)
        .font(.headline)
      
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
                cards[index].getImageURL().map {
                  AmbientWebImage(url: $0)
                }
              }
            )
            .buttonStyle(.sinkableButtonStyle)
            .frame(width: 150, height: 150 * 1.3928 + 26, alignment: .center)
          }
        }
      }
    }
    .safeAreaPadding(.horizontal, nil)
  }
  
  init(
    title: String,
    cards: [any MagicCard],
    send: @escaping (Action) -> Void
  ) {
    self.title = title
    self.cards = cards
    self.send = send
  }
}

#Preview {
  VariantView(
    title: "Relevant Cards",
    cards: [
      MagicCardFixtures.split.value,
      MagicCardFixtures.split.value,
      MagicCardFixtures.split.value,
      MagicCardFixtures.split.value
    ]
  ) { action in
    print(action)
  }
}
