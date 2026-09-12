import ComposableArchitecture
import DesignComponents
import Networking
import Nuke
import NukeUI
import SwiftUI

public struct CardDetailView: View {
  @Bindable var store: StoreOf<CardDetailFeature>
  // Seed value only; corrected by `onGeometryChange` on the first layout pass.
  @State private var maxWidth: CGFloat = .initialScreenWidth
  @Environment(\.displayScale) private var displayScale
  
  public init(store: StoreOf<CardDetailFeature>) {
    self.store = store
  }
  
  public var body: some View {
    let _ = Self._printChanges()
    
    let content = store.content
    let faceDirection = store.displayableCardImage?.faceDirection
    
    ScrollView(.vertical) {
      VStack(spacing: 0) {
        let cardImageWidth = content.card.isLandscape
        ? 2.5 / 3.0 * maxWidth
        : 2.0 / 3.0 * maxWidth
        
        let configuration = CardView.LayoutConfiguration(
          rotation: content.card.isLandscape ? .landscape : .portrait,
          maxWidth: cardImageWidth.rounded()
        )
        
        CardView(
          displayableCard: store.displayableCardImage,
          layoutConfiguration: configuration,
          callToActionHorizontalOffset: 21.0,
          priceVisibility: .hidden,
          shadowConfiguration: .default,
          isFoilOnly: content.card.availableFoilness == true
        ) { action in
          store.send(.descriptionCallToActionTapped, animation: .bouncy)
        }
        // NOTE: .equatable() only works if CardView conforms to `Equatable`.
        .padding(
          EdgeInsets(top: 13, leading: 55, bottom: 34, trailing: 55)
        )
        .zIndex(1)
        
        CardDetailTableView(descriptions: content.getDescriptions(faceDirection: faceDirection))
        
        InformationSectionView(
          store: store,
          content: content,
          faceDirection: faceDirection
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
            .background(DesignComponentsAsset.accentColor.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
              RoundedRectangle(cornerRadius: 13)
                .strokeBorder(.separator, lineWidth: 1 / displayScale)
            )
          }
          .buttonStyle(.sinkableButtonStyle)
          .safeAreaPadding(.horizontal, systemHorizontalMargin)
        }
        
        if content.card.isTransformable || content.card.isFlippable {
          Spacer(minLength: 13.0)
        }
        
        PriceHistorySectionView(
          store: store,
          title: content.priceHistoryLabel,
          sourceLabel: content.priceHistorySourceLabel,
          unavailableLabel: content.priceHistoryUnavailableLabel
        )
        
        PurchaseLinksView(
          title: content.purchaseLabel,
          subtitle: content.purchaseSubtitleLabel,
          listings: MarketplaceListing.listings(
            purchaseURIs: content.card.purchaseUris,
            prices: content.card.prices
          ),
          finishLabel: { kind in
            switch kind {
            case .normal: content.usdLabel
            case .foil: content.usdFoilLabel
            case .etched: content.usdEtchedLabel
            }
          }
        )
        
        LegalityView(
          title: content.legalityLabel,
          displayReleaseDate: content.card.releasedAt,
          legalities: content.card.legalities.all
        )
        
        VariantsSectionView(store: store)
        RelatedTokensSectionView(store: store)
        RelatedComboPiecesSectionView(store: store)
        RelatedMeldPiecesSectionView(store: store)
        RelatedMeldResultSectionView(store: store)
        
        SelectionView(
          items: [
            SelectionView.Item(
              icon: content.artistSelectionIcon,
              title: content.artistSelectionLabel,
              detail: content.card.artist
            ) {},
            SelectionView.Item(
              icon: content.rulingSelectionIcon,
              title: content.rulingSelectionLabel
            ) {
              store.send(.viewRulingsTapped)
            },
          ]
        )
      }
      .onGeometryChange(for: CGFloat.self, of: { proxy in
        proxy.size.width
      }, action: { newValue in
        if abs(maxWidth - newValue) > 5.0 {
          maxWidth = newValue
        }
      })
    }
    .accessibilityIdentifier("cardDetail.scroll")
    .background {
      ZStack {
        backdrop(for: content.card.getImageURL(type: .normal))
          .opacity((store.displayableCardImage?.faceDirection == .front) ? 1 : 0)
        
        backdrop(for: content.card.getImageURL(type: .normal, getSecondFace: true))
          .opacity((store.displayableCardImage?.faceDirection == .back) ? 1 : 0)
        
        Color(asset: DesignComponentsAsset.backgroundPlaceholder)
      }
      .ignoresSafeArea()
    }
  }
  
  private func backdrop(for url: URL?) -> some View {
    LazyImage(
      request: ImageRequest(url: url, processors: [ArtCropImageProcessor()]),
      transaction: Transaction(animation: .smooth)
    ) { state in
      if let image = state.image {
        image
          .resizable()
          .blur(radius: 89, opaque: true)
      }
    }
  }
}

private extension CGFloat {
  @MainActor static var initialScreenWidth: CGFloat {
    UIApplication.shared.connectedScenes
      .lazy
      .compactMap { $0 as? UIWindowScene }
      .first?
      .screen.bounds.width ?? 0
  }
}

private struct PriceHistorySectionView: View {
  let store: StoreOf<CardDetailFeature>
  let title: String
  let sourceLabel: String
  let unavailableLabel: String
  
  var body: some View {
    PriceHistoryView(
      state: store.priceHistory,
      title: title,
      sourceLabel: sourceLabel,
      unavailableLabel: unavailableLabel
    )
  }
}

private struct InformationSectionView: View {
  let store: StoreOf<CardDetailFeature>
  let content: Content
  let faceDirection: MagicCardFaceDirection?
  
  var body: some View {
    InformationView(
      title: content.infoLabel,
      power: content.getPower(faceDirection: faceDirection),
      toughness: content.getToughtness(faceDirection: faceDirection),
      loyaltyCounters: content.getLoyalty(faceDirection: faceDirection),
      manaValue: content.card.cmc,
      rarity: content.card.rarity,
      collectorNumber: content.card.collectorNumber,
      colorIdentity: content.getColorIdentity(),
      setCode: content.card.set,
      setIconURL: store.setIconURL
    )
  }
}

private struct VariantsSectionView: View {
  let store: StoreOf<CardDetailFeature>
  
  var body: some View {
    let variants = store.variants
    
    if let cards = variants.state.value {
      HorizontalCardScrollView(
        title: variants.title,
        subtitle: variants.subtitle,
        cards: cards,
        isInitial: variants.state.isInitial
      ) { [store] action in
        switch action {
        case let .didSelectCard(card):
          store.send(.didSelectVariant(card: card, queryType: store.content.queryType))
          
        case let .didShowCardAtIndex(index):
          store.send(.didShowVariant(index: index))
        }
      }
    }
  }
}

private struct RelatedTokensSectionView: View {
  let store: StoreOf<CardDetailFeature>
  var body: some View { RelatedCardsSectionView(section: store.relatedTokens) }
}

private struct RelatedComboPiecesSectionView: View {
  let store: StoreOf<CardDetailFeature>
  var body: some View { RelatedCardsSectionView(section: store.relatedComboPieces) }
}

private struct RelatedMeldPiecesSectionView: View {
  let store: StoreOf<CardDetailFeature>
  var body: some View { RelatedCardsSectionView(section: store.relatedMeldPieces) }
}

private struct RelatedMeldResultSectionView: View {
  let store: StoreOf<CardDetailFeature>
  var body: some View { RelatedCardsSectionView(section: store.relatedMeldResult) }
}

private struct RelatedCardsSectionView: View {
  let section: Content.SubContent?
  
  var body: some View {
    if let section, let cards = section.state.value {
      HorizontalCardScrollView(
        title: section.title,
        subtitle: section.subtitle,
        cards: cards,
        isInitial: section.state.isInitial
      ) { _ in }
    }
  }
}
