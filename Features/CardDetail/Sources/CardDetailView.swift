import ComposableArchitecture
import DesignComponents
import Networking
import NukeUI
import SwiftUI

struct CardDetailView<Client: MagicCardDetailRequestClient>: View {
  @Bindable private var store: StoreOf<CardDetailFeature<Client>>
  
  init(
    store: StoreOf<CardDetailFeature<Client>>
  ) {
    self.store = store
  }
  
  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: 0) {
        let configuration = CardView<Client.MagicCardModel>.LayoutConfiguration(
          rotation: store.content.card.isLandscape ? .landscape : .portrait,
          maxWidth: nil
        )
        CardView(
          mode: store.content.selectedMode,
          layoutConfiguration: configuration,
          callToActionHorizontalOffset: 21.0,
          priceVisibility: .hidden
        ) { action in
          store.send(.descriptionCallToActionTapped, animation: .bouncy)
        }
        .aspectRatio(configuration.rotation.ratio, contentMode: .fit)
        .padding(
          EdgeInsets(
            top: 21,
            leading: store.content.card.isLandscape ? 34 : 89.0,
            bottom: 29.0,
            trailing: store.content.card.isLandscape ? 34 : 89.0
          )
        )
        .shadow(color: DesignComponentsAsset.shadow.swiftUIColor, radius: 13, x: 0, y: 13)
        .zIndex(1)
        
        CardDetailTableView(
          descriptions: store.content.descriptions,
          keywords: store.content.keywords
        )
        
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
        
        if let label = store.content.descriptionCallToActionLabel, let icon = store.content.descriptionCallToActionIconName {
          Button {
            store.send(.descriptionCallToActionTapped, animation: .bouncy)
          } label: {
            Label {
              Text(label)
                .font(.body)
                .fontWeight(.semibold)
            } icon: {
              Image(systemName: icon)
                .fontWeight(.semibold)
            }
            .foregroundStyle(DesignComponentsAsset.invertedPrimary.swiftUIColor)
            .frame(maxWidth: .infinity, minHeight: 34)
            .padding(.vertical, 5.0)
            .background(DesignComponentsAsset.accentColor.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 13))
          }
          .buttonStyle(.sinkableButtonStyle)
          .safeAreaPadding(.horizontal, nil)
        }
        
        if store.content.card.isTransformable || store.content.card.isFlippable {
          Spacer(minLength: 13.0)
        }
        
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
          cards: store.content.variants
        ) { action in
          switch action {
          case .didSelectCard:
            break
          }
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
              store.send(.viewRulingsTapped)
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
    .task {
      store.send(.fetchAdditionalInformation(card: store.content.card))
    }
    .background {
      ZStack {
        LazyImage(
          url: store.content.artCroppedImageURL(with: .front),
          transaction: Transaction(animation: .default)
        ) { state in
          if let image = state.image {
            image.resizable().blur(radius: 34, opaque: true)
          }
        }
        .opacity((store.content.faceDirection == .front) ? 1 : 0)
        
        LazyImage(
          url: store.content.artCroppedImageURL(with: .back),
          transaction: Transaction(animation: .default)
        ) { state in
          if let image = state.image {
            image.resizable().blur(radius: 89, opaque: true)
          }
        }
        .opacity((store.content.faceDirection == .back) ? 1 : 0)
        
        Color(asset: DesignComponentsAsset.backgroundPlaceholder)
      }
      .ignoresSafeArea(.all, edges: .all)
    }
    .sheet(
      item: $store.scope(state: \.showRulings, action: \.showRulings)
    ) { store in
      NavigationStack {
        RulingView(store: store).toolbarTitleDisplayMode(.inline)
      }
    }
  }
}
