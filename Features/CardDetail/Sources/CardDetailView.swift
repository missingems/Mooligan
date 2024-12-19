import ComposableArchitecture
import DesignComponents
import Networking
import NukeUI
import SwiftUI

struct CardDetailView<Client: MagicCardDetailRequestClient>: View {
  @Bindable private var store: StoreOf<CardDetailFeature<Client>>
  private let geometryProxy: GeometryProxy
  
  init(
    geometryProxy: GeometryProxy,
    store: StoreOf<CardDetailFeature<Client>>
  ) {
    self.geometryProxy = geometryProxy
    self.store = store
  }
  
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        Self.cardView(store: store, geometryProxy: geometryProxy)
        
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
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") {
                self.store.send(.dismissRulingsTapped)
              }
              .buttonStyle(.borderSinkableButtonStyle)
            }
          }
      }
    }
    .task(priority: .background) {
      store.send(.fetchAdditionalInformation(card: store.content.card))
    }
  }
}

private extension CardDetailView {
  @ViewBuilder static func cardView(
    store: StoreOf<CardDetailFeature<Client>>,
    geometryProxy: GeometryProxy
  ) -> some View {
    let insets: EdgeInsets = if store.content.card.isLandscape {
      EdgeInsets(top: 21.0, leading: 34.0, bottom: 29.0, trailing: 34.0)
    } else {
      EdgeInsets(top: 21.0, leading: 68, bottom: 29.0, trailing: 68)
    }
    
    CardView(
      card: store.content.card,
      layoutConfiguration: CardView.LayoutConfiguration(
        rotation: store.content.card.isLandscape ? .landscape : .portrait,
        maxWidth: geometryProxy.size.width - insets.leading - insets.trailing
      ),
      callToActionHorizontalOffset: 21.0
    ) { action in
      store.send(.descriptionCallToActionTapped, animation: .bouncy)
    }
    .padding(insets)
    .zIndex(1)
    .shadow(color: DesignComponentsAsset.shadow.swiftUIColor, radius: 13, x: 0, y: 13)
  }
}
