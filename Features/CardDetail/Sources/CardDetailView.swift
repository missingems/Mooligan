import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct ContentOffsetKey: PreferenceKey {
  typealias Value = CGFloat
  static let defaultValue = CGFloat.zero
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value += nextValue()
  }
}

@MainActor struct ObservableScrollView<Content: View>: View {
  let content: Content
  @Binding var contentOffset: CGFloat
  
  init(contentOffset: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
    self._contentOffset = contentOffset
    self.content = content()
  }
  
  var body: some View {
    ScrollView {
      content
        .background {
          GeometryReader { geometry in
            Color.clear
              .preference(key: ContentOffsetKey.self, value: geometry.frame(in: .named("scrollView")).minY)
          }
        }
    }
    .coordinateSpace(name: "scrollView")
    .onPreferenceChange(ContentOffsetKey.self) { value in
      self.contentOffset = value
    }
  }
}

struct CardDetailView<Client: MagicCardDetailRequestClient>: View {
  @Bindable var store: StoreOf<Feature<Client>>
  
  var body: some View {
    GeometryReader { proxy in
      ObservableScrollView(contentOffset: $store.contentOffset) {
        VStack(alignment: .leading, spacing: 0) {
          HeaderView(
            imageURL: store.content.imageURL,
            isFlippable: store.content.card.isFlippable,
            orientation: store.content.card.isSplit ? .landscape : .portrait,
            rotation: 90.0
          )
          .padding(.bottom, 8.0)
          
          Divider()
            .safeAreaPadding(.leading, nil)
          
          CardDetailTableView(descriptions: store.content.descriptions)
          
          Divider()
            .safeAreaPadding(.leading, nil)
          
          InfoView(
            title: store.content.infoLabel,
            power: store.content.power,
            toughness: store.content.toughness,
            loyaltyCounters: store.content.loyalty,
            manaValue: store.content.manaValue,
            collectorNumber: store.content.collectorNumber,
            colorIdentity: store.content.colorIdentity,
            setCode: store.content.setCode,
            setIconURL: try? store.content.setIconURL.get()
          )
          .padding(.vertical, 13.0)
          
          Divider()
            .safeAreaPadding(.leading, nil)
          
          LegalityView(
            title: store.content.legalityLabel,
            displayReleaseDate: store.content.displayReleasedDate,
            legalities: store.content.legalities
          )
          .padding(.vertical, 13.0)
          
          Divider()
            .safeAreaPadding(.leading, nil)
          
          PriceView(
            title: store.content.priceLabel,
            subtitle: store.content.priceSubtitleLabel,
            prices: store.content.card.getPrices(),
            usdLabel: store.content.usdLabel,
            usdFoilLabel: store.content.usdFoilLabel,
            tixLabel: store.content.tixLabel,
            purchaseVendor: store.content.card.getPurchaseUris()
          )
          .padding(.vertical, 13.0)
          
          Divider()
            .safeAreaPadding(.leading, nil)
          
          VariantView(
            title: store.content.variantLabel,
            subtitle: store.content.numberOfVariantsLabel,
            cards: try? store.content.variants?.get()
          ) { action in
          }
          .padding(.vertical, 13.0)
          
          SelectionView(
            items: [
              SelectionView.Item(
                icon: store.content.artistSelectionIcon,
                title: store.content.artistSelectionLabel,
                detail: store.content.artist
              ) {
                
              },
              SelectionView.Item(
                icon: store.content.rulingSelectionIcon,
                title: store.content.rulingSelectionLabel
              ) {
                
              },
              SelectionView.Item(
                icon: store.content.relatedSelectionIcon,
                title: store.content.relatedSelectionLabel
              ) {
                
              },
            ]
          )
          .padding(.vertical, 13.0)
        }
      }
      .background {
        Color(.secondarySystemBackground).ignoresSafeArea()
      }
    }
    .task {
      store.send(.viewAppeared(initialAction: store.start))
    }
  }
}

//#Preview {
//  CardDetailView(
//    store: Store(
//      initialState: Feature.State(card: MagicCardFixtures.split.value, entryPoint: .query)
//    ) {
//      Feature(
//        client: MockMagicCardDetailRequestClient<MockMagicCard<MockMagicCardColor>>(
//          testConfiguration: .successFlow
//        )
//      )
//    },
//    contentOffset: .constant(0)
//  )
//}
