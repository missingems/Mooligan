import ComposableArchitecture
import DesignComponents
import VariableBlur
import Networking
import SwiftUI

struct CardDetailView<Client: MagicCardDetailRequestClient>: View {
  @Bindable var store: StoreOf<CardDetailFeature<Client>>
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
      LazyVStack(spacing: 0, pinnedViews: .sectionFooters) {
        Section {
          CardView(
            imageURL: store.content.imageURL,
            backImageURL: store.content.card.getCardFace(for: .back).getImageURL(),
            isTransformable: store.content.card.isTransformable,
            isTransformed: $store.isTransformed,
            isFlippable: store.content.card.isFlippable,
            isFlipped: $store.isFlipped,
            layoutConfiguration: CardView.LayoutConfiguration(
              rotation: store.content.card.isLandscape ? .landscape : .portrait,
              layout: .flexible
            ),
            usdPrice: nil,
            usdFoilPrice: nil,
            shouldShowPrice: false
          )
          .aspectRatio(layoutConfiguration.rotation.ratio, contentMode: .fit)
          .shadow(color: .black.opacity(0.31), radius: 13, x: 0, y: 13)
          .padding(layoutConfiguration.insets)
          .safeAreaPadding(.horizontal, nil)
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
        } footer: {
          if store.content.card.isTransformable {
            Button {
              store.send(.transformTapped, animation: .bouncy)
            } label: {
                Label {
                  Text("Transform")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
                } icon: {
                  Image(systemName: "arrow.left.arrow.right")
                }
                .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
                .frame(maxWidth: .infinity, minHeight: 34)
                .padding(.vertical, 5.0)
                .background(Color.primary.opacity(0.02).background(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.sinkableButtonStyle)
            .safeAreaPadding(.horizontal, nil)
            .background(
              alignment: .top,
              content: {
                VariableBlurView(
                  maxBlurRadius: 13.0,
                  direction: .blurredBottomClearTop,
                  startOffset: 0
                )
                .frame(height: 144.0)
                .offset(x: 0, y: -15)
              }
            )
          }
        }
        .zIndex(0)
        
        if store.content.card.isTransformable {
          Spacer(minLength: 13.0)
        }
        
        LegalityView(
          title: store.content.legalityLabel,
          displayReleaseDate: store.content.displayReleasedDate,
          legalities: store.content.legalities
        )
        .zIndex(1)
        
        PriceView(
          title: store.content.priceLabel,
          subtitle: store.content.priceSubtitleLabel,
          prices: store.content.card.getPrices(),
          usdLabel: store.content.usdLabel,
          usdFoilLabel: store.content.usdFoilLabel,
          tixLabel: store.content.tixLabel,
          purchaseVendor: store.content.card.getPurchaseUris()
        )
        .zIndex(1)
        
        VariantView(
          title: store.content.variantLabel,
          subtitle: store.content.numberOfVariantsLabel,
          cards: try? store.content.variants.get()
        ) { action in
          
        }
        .zIndex(1)
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
      EdgeInsets(top: 21, leading: 0, bottom: 29, trailing: 0)
      
    case .portrait:
      EdgeInsets(top: 21, leading: 55, bottom: 29, trailing: 55)
    }
  }
}

