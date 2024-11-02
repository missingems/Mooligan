import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct CardDetailView<Client: MagicCardDetailRequestClient>: View {
  @State var store: StoreOf<Feature<Client>>
  
  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          HeaderView(
            imageURL: store.content.imageURL,
            isFlippable: store.content.card.isFlippable,
            orientation: store.content.card.isLandscape ? .landscape : .portrait,
            rotation: store.content.card.isLandscape ? 90 : 0
          )?.clipped()
          
          CardDetailTableView(descriptions: store.content.descriptions)
          
          InformationView(
            title: store.content.infoLabel,
            power: store.content.power,
            toughness: store.content.toughness,
            loyaltyCounters: store.content.loyalty,
            manaValue: store.content.manaValue,
            rarity: store.content.rarity,
            collectorNumber: store.content.collectorNumber,
            colorIdentity: store.content.colorIdentity,
            setCode: store.content.setCode,
            setIconURL: try? store.content.setIconURL.get()
          )
          
          LegalityView(
            title: store.content.legalityLabel,
            displayReleaseDate: store.content.displayReleasedDate,
            legalities: store.content.legalities
          )
          
          PriceView(
            title: store.content.priceLabel,
            subtitle: store.content.priceSubtitleLabel,
            prices: store.content.card.getPrices(),
            usdLabel: store.content.usdLabel,
            usdFoilLabel: store.content.usdFoilLabel,
            tixLabel: store.content.tixLabel,
            purchaseVendor: store.content.card.getPurchaseUris()
          )
          
          VariantView(
            title: store.content.variantLabel,
            subtitle: store.content.numberOfVariantsLabel,
            cards: try? store.content.variants.get()
          ) { action in
          }
          
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
        }
      }
      .background {
        Color(.systemBackground).ignoresSafeArea()
      }
    }
    .task {
      store.send(.viewAppeared(initialAction: store.start))
    }
  }
}
