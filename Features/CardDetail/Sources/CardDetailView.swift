import ComposableArchitecture
import DesignComponents
import Networking
import NukeUI
import SwiftUI

struct CardDetailView: View {
  @Bindable var store: StoreOf<CardDetailFeature>
  @State private var maxWidth: CGFloat?
  
  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: 0) {
        if let content = store.content {
          if let maxWidth, maxWidth > 0 {
            let cardImageWidth = content.card.isLandscape ? 2.5 / 3.0 * maxWidth : 2.0 / 3.0 * maxWidth
            
            let configuration = CardView.LayoutConfiguration(
              rotation: content.card.isLandscape ? .landscape : .portrait,
              maxWidth: cardImageWidth.rounded()
            )
            
            CardView(
              displayableCard: content.displayableCardImage,
              layoutConfiguration: configuration,
              callToActionHorizontalOffset: 21.0,
              priceVisibility: .hidden
            ) { action in
              store.send(.descriptionCallToActionTapped, animation: .bouncy)
            }
            .shadow(color: DesignComponentsAsset.shadow.swiftUIColor, radius: 8, x: 0, y: 5)
            .padding(
              EdgeInsets(
                top: 13,
                leading: 0,
                bottom: 21,
                trailing: 0
              )
            )
            .zIndex(1)
          }
          
          CardDetailTableView(descriptions: store.content?.getDescriptions() ?? [])
          
          InformationView(
            title: content.infoLabel,
            power: content.getPower(),
            toughness: content.getToughtness(),
            loyaltyCounters: content.getLoyalty(),
            manaValue: content.card.cmc,
            rarity: content.card.rarity,
            collectorNumber: content.card.collectorNumber,
            colorIdentity: content.getColorIdentity(),
            setCode: content.card.set,
            setIconURL: content.setIconURL
          )
          
          if let label = content.card.layout.callToActionLabel,
             let icon = content.card.layout.callToActionIconName {
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
              .background(
                DesignComponentsAsset.accentColor.swiftUIColor
              )
              .clipShape(RoundedRectangle(cornerRadius: 13))
              .overlay(
                RoundedRectangle(cornerRadius: 13)
                  .strokeBorder(.separator, lineWidth: 1 / UIScreen.main.nativeScale)
              )
            }
            .buttonStyle(.sinkableButtonStyle)
            .safeAreaPadding(.horizontal, nil)
          }
          
          if content.card.isTransformable || content.card.isFlippable {
            Spacer(minLength: 13.0)
          }
          
          LegalityView(
            title: content.legalityLabel,
            displayReleaseDate: content.card.releasedAt,
            legalities: content.card.legalities.all
          )
          
          PriceView(
            title: content.priceLabel,
            subtitle: content.priceSubtitleLabel,
            prices: content.card.prices,
            usdLabel: content.usdLabel,
            usdFoilLabel: content.usdFoilLabel,
            tixLabel: content.tixLabel,
            purchaseVendor: PurchaseVendor(purchaseURIs: content.card.purchaseUris)
          )
          
          if let state = content.variants.state.value {
            HorizontalCardScrollView(
              title: content.variants.title,
              subtitle: content.variants.subtitle,
              cards: state,
              isInitial: content.variants.state.isInitial
            ) { action in
              switch action {
              case let .didSelectCard(card):
                store.send(
                  .didSelectVariant(
                    card: card,
                    queryType: content.queryType
                  )
                )
                
              case let .didShowCardAtIndex(index):
                store.send(.didShowVariant(index: index))
              }
            }
          }
          
          if let relatedTokensSection = content.relatedTokens,
             let state = relatedTokensSection.state.value {
            HorizontalCardScrollView(
              title: relatedTokensSection.title,
              subtitle: relatedTokensSection.subtitle,
              cards: state,
              isInitial: relatedTokensSection.state.isInitial
            ) { action in
              switch action {
              case let .didSelectCard(card):
                print(card)
                
              case let .didShowCardAtIndex(index):
                print(index)
              }
            }
          }
          
          if let relatedComboPiecesSection = content.relatedComboPieces,
             let state = relatedComboPiecesSection.state.value {
            HorizontalCardScrollView(
              title: relatedComboPiecesSection.title,
              subtitle: relatedComboPiecesSection.subtitle,
              cards: state,
              isInitial: relatedComboPiecesSection.state.isInitial
            ) { action in
              switch action {
              case let .didSelectCard(card):
                print(card)
                
              case let .didShowCardAtIndex(index):
                print(index)
              }
            }
          }
          
          if let relatedMeldPiecesSection = content.relatedMeldPieces,
             let state = relatedMeldPiecesSection.state.value {
            HorizontalCardScrollView(
              title: relatedMeldPiecesSection.title,
              subtitle: relatedMeldPiecesSection.subtitle,
              cards: state,
              isInitial: relatedMeldPiecesSection.state.isInitial
            ) { action in
              switch action {
              case let .didSelectCard(card):
                print(card)
                
              case let .didShowCardAtIndex(index):
                print(index)
              }
            }
          }
          
          if let relatedMeldResultSection = content.relatedMeldResult,
             let state = relatedMeldResultSection.state.value {
            HorizontalCardScrollView(
              title: relatedMeldResultSection.title,
              subtitle: relatedMeldResultSection.subtitle,
              cards: state,
              isInitial: relatedMeldResultSection.state.isInitial
            ) { action in
              switch action {
              case let .didSelectCard(card):
                print(card)
                
              case let .didShowCardAtIndex(index):
                print(index)
              }
            }
          }
          
          SelectionView(
            items: [
              SelectionView.Item(
                icon: content.artistSelectionIcon,
                title: content.artistSelectionLabel,
                detail: content.card.artist
              ) {
                
              },
              SelectionView.Item(
                icon: content.rulingSelectionIcon,
                title: content.rulingSelectionLabel
              ) {
                store.send(.viewRulingsTapped)
              },
              SelectionView.Item(
                icon: content.relatedSelectionIcon,
                title: content.relatedSelectionLabel
              ) {
                
              },
            ]
          )
        }
      }
    }
    .onGeometryChange(for: CGFloat.self, of: { proxy in
      proxy.size.width
    }, action: { newValue in
      maxWidth = newValue
    })
    .background {
      ZStack {
        if let content = store.content {
          LazyImage(
            url: content.card.getImageURL(type: .artCrop),
            transaction: Transaction(animation: .smooth)
          ) { state in
            if let image = state.image {
              image.resizable().blur(radius: 34, opaque: true)
            }
          }
          .opacity((content.displayableCardImage?.faceDirection == .front) ? 1 : 0)
          
          LazyImage(
            url: content.card.getImageURL(type: .artCrop, getSecondFace: true),
            transaction: Transaction(animation: .smooth)
          ) { state in
            if let image = state.image {
              image.resizable().blur(radius: 89, opaque: true)
            }
          }
          .opacity((content.displayableCardImage?.faceDirection == .back) ? 1 : 0)
          
          Color(asset: DesignComponentsAsset.backgroundPlaceholder)
        }
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
    .task {
      store.send(.viewAppeared(initialAction: store.start))
    }
  }
}
