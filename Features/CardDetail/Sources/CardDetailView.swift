import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct CardDetailView<Client: MagicCardDetailRequestClient>: View {
  let store: StoreOf<Feature<Client>>
  
  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          HeaderView(
            imageURL: store.content.imageURL,
            isFlippable: store.content.card.isFlippable,
            orientation: .portrait,
            rotation: 0
          )
          
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
            tixLabel: store.content.tixLabel
          ) { action in
          }
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

#Preview {
  CardDetailView(
    store: Store(
      initialState: Feature.State(card: MagicCardFixtures.split.value, entryPoint: .query)
    ) {
      Feature(
        client: MockMagicCardDetailRequestClient<MockMagicCard<MockMagicCardColor>>(
          testConfiguration: .successFlow
        )
      )
    }
  )
}
