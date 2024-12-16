import DesignComponents
import Networking
import SwiftUI

struct CellView: View {
  @State var isSelected: Bool
  
  let title: String
  
  var body: some View {
    let _ = Self._printChanges()
    VStack {
      LazyHStack {
        Button {
          withAnimation {
            
            isSelected.toggle()
          }
        } label: {
          Text("Toggle")
        }
      }
      
      Text(title).opacity(isSelected ? 0 : 1)
    }
  }
}

struct VariantView<Card: MagicCard>: View {
  enum Action: Sendable, Equatable {
    case didSelectCard(Card)
  }
  
  let title: String
  let subtitle: String
  let cards: [Card]
  let send: (Action) -> Void
  
  var body: some View {
    Divider().safeAreaPadding(.leading, nil)
    
    VStack(alignment: .leading, spacing: 5.0) {
      Text(title).font(.headline)
      Text(subtitle).font(.caption).foregroundStyle(.secondary)
      
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 8.0) {
          ForEach(cards) { card in
            CellView(isSelected: false, title: card.getName())
//            Button(
//              action: {
//                send(.didSelectCard(card))
//              }, label: {
//                CardView(
//                  imageURL: card.getImageURL(),
//                  backImageURL: card.getCardFace(for: .back).getImageURL(),
//                  isTransformable: card.isTransformable,
//                  isFlippable: card.isFlippable,
//                  layoutConfiguration: CardView.LayoutConfiguration(
//                    rotation: .portrait,
//                    layout: .fixedWidth(170)
//                  ),
//                  usdPrice: card.getPrices().usd,
//                  usdFoilPrice: card.getPrices().usdFoil,
//                  callToActionIconName: card.getLayout().value.callToActionIconName
//                )
//              }
//            )
//            .buttonStyle(.sinkableButtonStyle)
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
