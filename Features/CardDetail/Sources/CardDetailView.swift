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
          shadowConfiguration: .default
        ) { action in
          store.send(.descriptionCallToActionTapped, animation: .bouncy)
        }
        .padding(
          EdgeInsets(top: 13, leading: 55, bottom: 34, trailing: 55)
        )
        .zIndex(1)
        
        CardDetailTableView(descriptions: content.getDescriptions(faceDirection: faceDirection))
        
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
        
        LegalityView(
          title: content.legalityLabel,
          displayReleaseDate: content.card.releasedAt,
          legalities: content.card.legalities.all
        )
        
        // Reads `store.priceHistory` inside its own body rather than here, so
        // the history landing re-renders this section and nothing else.
        PriceHistorySectionView(
          store: store,
          quotes: content.todaysQuotes,
          title: content.priceHistoryLabel,
          sourceLabel: content.priceHistorySourceLabel,
          unavailableLabel: content.priceHistoryUnavailableLabel
        )

        // Buying comes after the history, not before it: the chart is what tells
        // you whether now is the moment, and these are the places to act on it.
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

        ObservedSection(store: store) { store in
          if let section = store.variants.state.value {
            HorizontalCardScrollView(
              title: store.variants.title,
              subtitle: store.variants.subtitle,
              cards: section,
              isInitial: store.variants.state.isInitial
            ) { action in
              switch action {
            case let .didSelectCard(card):
                store.send(.didSelectVariant(card: card, queryType: store.content.queryType))
              case let .didShowCardAtIndex(index):
                store.send(.didShowVariant(index: index))
              }
            }
          }
        }
        
        ObservedSection(store: store) { store in
          if let relatedTokensSection = store.relatedTokens,
             let cards = relatedTokensSection.state.value {
            HorizontalCardScrollView(
              title: relatedTokensSection.title,
              subtitle: relatedTokensSection.subtitle,
              cards: cards,
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
        }
        
        ObservedSection(store: store) { store in
          if let relatedComboPiecesSection = store.relatedComboPieces,
             let cards = relatedComboPiecesSection.state.value {
            HorizontalCardScrollView(
              title: relatedComboPiecesSection.title,
              subtitle: relatedComboPiecesSection.subtitle,
              cards: cards,
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
        }
        
        ObservedSection(store: store) { store in
          if let relatedMeldPiecesSection = store.relatedMeldPieces,
             let cards = relatedMeldPiecesSection.state.value {
            HorizontalCardScrollView(
              title: relatedMeldPiecesSection.title,
              subtitle: relatedMeldPiecesSection.subtitle,
              cards: cards,
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
        }
        
        ObservedSection(store: store) { store in
          if let relatedMeldResultSection = store.relatedMeldResult,
             let cards = relatedMeldResultSection.state.value {
            HorizontalCardScrollView(
              title: relatedMeldResultSection.title,
              subtitle: relatedMeldResultSection.subtitle,
              cards: cards,
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
        }
        
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
        if abs(maxWidth - newValue) > 1.0 {
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
  /// Width of the active window scene's screen.
  ///
  /// `UIScreen.main` is deprecated in iOS 26 — the screen must be reached
  /// through the view's context instead. This is used purely as a pre-layout
  /// seed, so falling back to zero is safe.
  @MainActor static var initialScreenWidth: CGFloat {
    UIApplication.shared.connectedScenes
      .lazy
      .compactMap { $0 as? UIWindowScene }
      .first?
      .screen.bounds.width ?? 0
  }
}


/// The price-history chart, isolated from the rest of the card.
///
/// Its whole reason for existing as a separate view is observation scope: the
/// chart arrives seconds after everything else, often while the reader is still
/// scrolling, and re-rendering the entire card detail at that moment is what
/// they feel as a stutter. Reading `store.priceHistory` here and nowhere else
/// confines the update to this section.
private struct PriceHistorySectionView: View {
  let store: StoreOf<CardDetailFeature>
  let quotes: [PriceHistoryChartView.Quote]
  let title: String
  let sourceLabel: String
  let unavailableLabel: String

  var body: some View {
    PriceHistoryChartView(
      state: store.priceHistory,
      quotes: quotes,
      title: title,
      sourceLabel: sourceLabel,
      unavailableLabel: unavailableLabel
    )
  }
}


/// Renders its content inside a body of its own.
///
/// Observation is recorded where a value is *read*, so a section that reads its
/// slice of the store in here depends on that slice alone — a token list
/// arriving re-renders this wrapper and nothing else. Read from the parent's
/// body instead and the whole card detail screen rebuilds, which lands as a
/// stutter whenever one of these requests finishes mid-scroll.
private struct ObservedSection<Body: View>: View {
  let store: StoreOf<CardDetailFeature>
  @ViewBuilder var content: (StoreOf<CardDetailFeature>) -> Body

  var body: some View {
    content(store)
  }
}
