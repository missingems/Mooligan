import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct CardDetailView<Client: MagicCardDetailRequestClient>: View {
  let store: StoreOf<CardDetailFeature<Client>>
  let layoutConfiguration: CardView.LayoutConfiguration
  
  init(store: StoreOf<CardDetailFeature<Client>>) {
    self.store = store
    layoutConfiguration = CardView.LayoutConfiguration(
      rotation: store.content.card.isLandscape ? .landscape : .portrait,
      layout: .flexible
    )
  }
  
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        CardView(
          imageURL: store.content.imageURL,
          backImageURL: store.content.card.getCardFace(for: .back).getImageURL(),
          isFlippable: store.content.card.isFlippable,
          isRotatable: store.content.card.isRotatable,
          layoutConfiguration: CardView.LayoutConfiguration(
            rotation: store.content.card.isLandscape ? .landscape : .portrait,
            layout: .flexible
          ),
          usdPrice: nil,
          usdFoilPrice: nil,
          shouldShowPrice: false
        ) {
          store.send(.transformTapped, animation: .bouncy)
        }
        .aspectRatio(layoutConfiguration.rotation.ratio, contentMode: .fit)
        .padding(layoutConfiguration.insets)
        .zIndex(1)
        
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
        
        if store.content.rulings.isEmpty == false {
          RulingView(
            rulings: store.content.rulings,
            title: store.content.viewRulingsLabel
          )
        }
      }
    }
    .task {
      store.send(.fetchAdditionalInformation(card: store.content.card))
    }
  }
}

private extension CardView.LayoutConfiguration {
  var insets: EdgeInsets {
    switch rotation {
    case .landscape:
      EdgeInsets(top: 21, leading: 34, bottom: 29, trailing: 34)
      
    case .portrait:
      EdgeInsets(top: 21, leading: 89, bottom: 29, trailing: 89)
    }
  }
}
