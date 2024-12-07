import ComposableArchitecture
import DesignComponents
import VariableBlur
import Networking
import NukeUI
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
            shouldShowPrice: false,
            callToActionIconName: store.content.card.getLayout().value.callToActionIconName,
            callToActionHorizontalOffset: 21.0
          )
          .aspectRatio(layoutConfiguration.rotation.ratio, contentMode: .fit)
          .padding(layoutConfiguration.insets)
          .safeAreaPadding(.horizontal, nil)
          .zIndex(1)
          .shadow(color: .primary.opacity(0.1), radius: 21, x: 0, y: 13)
          
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
              }
              .foregroundStyle(DesignComponentsAsset.invertedPrimary.swiftUIColor)
              .frame(maxWidth: .infinity, minHeight: 34)
              .padding(.vertical, 5.0)
              .background(DesignComponentsAsset.accentColor.swiftUIColor)
              .clipShape(RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.sinkableButtonStyle)
            .safeAreaPadding(.horizontal, nil)
            .background(
              alignment: .top,
              content: {
                VariableBlurView(
                  maxBlurRadius: 13.0,
                  direction: .blurredBottomClearTop
                )
                .frame(height: 144.0)
                .offset(x: 0, y: -15)
              }
            )
          }
        }
        .zIndex(0)
        
        if store.content.card.isTransformable || store.content.card.isFlippable {
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
      ZStack {
        LazyImage(
          url: store.content.artCroppedImageURL(with: .front),
          transaction: Transaction(animation: .easeInOut(duration: 2))
        ) { state in
          if let image = state.image {
            image.resizable()
          } else {
            Color.clear
          }
        }
        .opacity((store.content.faceDirection == .front) ? 1 : 0)
        
        LazyImage(
          url: store.content.artCroppedImageURL(with: .back),
          transaction: Transaction(animation: .easeInOut(duration: 2))
        ) { state in
          if let image = state.image {
            image.resizable()
          } else {
            Color.clear
          }
        }
        .opacity((store.content.faceDirection == .back) ? 1 : 0)
      }
      .blur(radius: 89, opaque: true)
      .overlay(Color.primary.colorInvert().opacity(0.8))
      .ignoresSafeArea(.all, edges: .all)
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
