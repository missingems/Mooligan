import ComposableArchitecture
import DesignComponents
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
    GeometryReader { proxy in
      ScrollView {
        VStack(spacing: 0) {
          CardView(
            imageURL: store.content.imageURL,
            backImageURL: store.content.card.getCardFace(for: .back).getImageURL(),
            isTransformable: store.content.card.isTransformable,
            isTransformed: $store.isTransformed,
            isFlippable: store.content.card.isFlippable,
            isFlipped: $store.isFlipped,
            layoutConfiguration: CardView.LayoutConfiguration(
              rotation: store.content.card.isLandscape ? .landscape : .portrait,
              layout: .fixedWidth(proxy.size.width - layoutConfiguration.insets.leading - layoutConfiguration.insets.trailing)
            ),
            usdPrice: nil,
            usdFoilPrice: nil,
            shouldShowPrice: false,
            callToActionIconName: store.content.card.getLayout().value.callToActionIconName,
            callToActionHorizontalOffset: 21.0
          )
          .shadow(color: DesignComponentsAsset.shadow.swiftUIColor, radius: 13, x: 0, y: 13)
          .padding(EdgeInsets(top: layoutConfiguration.insets.top, leading: 0, bottom: layoutConfiguration.insets.bottom, trailing: 0))
          .zIndex(1)
          
          CardDetailTableView(descriptions: store.content.descriptions, keywords: store.content.keywords)
          
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
            transaction: Transaction(animation: .easeInOut(duration: 2))
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
        .presentationDetents([.height(proxy.size.height / 1.618)])
      }
    }
    .task(priority: .background) {
      store.send(.fetchAdditionalInformation(card: store.content.card))
    }
  }
}

private extension CardView.LayoutConfiguration {
  var insets: EdgeInsets {
    switch rotation {
    case .landscape:
      EdgeInsets(top: 21, leading: 8, bottom: 29, trailing: 8)
      
    case .portrait:
      EdgeInsets(top: 21, leading: 89, bottom: 29, trailing: 89)
    }
  }
}
