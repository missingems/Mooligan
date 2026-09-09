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
          shadowConfiguration: .default,
          isFoilOnly: content.card.availableFoilness == true
        ) { action in
          store.send(.descriptionCallToActionTapped, animation: .bouncy)
        }
        .equatable()
        .padding(
          EdgeInsets(top: 13, leading: 55, bottom: 34, trailing: 55)
        )
        .zIndex(1)
        
        CardDetailTableView(descriptions: content.getDescriptions(faceDirection: faceDirection))
          .equatable()
        
        // Reads `store.setIconURL` inside its own body rather than here: the
        // icon is fetched after the screen is already up, and reading it from
        // this body made that late arrival rebuild the whole card.
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
        
        LegalityView(
          title: content.legalityLabel,
          displayReleaseDate: content.card.releasedAt,
          legalities: content.card.legalities.all
        )
        .equatable()
        
        // Reads `store.priceHistory` inside its own body rather than here, so
        // the history landing re-renders this section and nothing else.
        PriceHistorySectionView(
          store: store,
          quotes: content.todaysQuotes,
          title: content.priceHistoryLabel,
          sourceLabel: content.priceHistorySourceLabel,
          unavailableLabel: content.priceHistoryUnavailableLabel,
          // One legend row per finish this printing was made in, so the section
          // is already the height it will be when the history lands.
          legendRows: max(content.card.finishes.count, 1)
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
        .equatable()

        // Each row below reads one slice of the store, inside a body of its
        // own. Observation is recorded where a value is read, so a list landing
        // re-renders the row that was waiting on it and nothing else — read
        // them from here and the whole card rebuilds, which is what the reader
        // feels as a stutter when a request finishes mid-scroll.
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
        .equatable()
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
  let legendRows: Int

  var body: some View {
    PriceHistoryChartView(
      state: store.priceHistory,
      quotes: quotes,
      title: title,
      sourceLabel: sourceLabel,
      unavailableLabel: unavailableLabel,
      legendRows: legendRows
    )
    .equatable()
  }
}


/// The card's tiles: power, mana value, rarity, collector number, set.
///
/// Split out for one read. The set icon is fetched after the screen is already
/// up, and while `store.setIconURL` was read from `CardDetailView.body` that
/// late arrival invalidated the card image, the tables, the chart and every
/// list along with it.
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
    .equatable()
  }
}


/// Every other printing of this card.
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
          // Read when the row is tapped rather than when it is drawn, so the
          // query type is not part of what this view observes.
          store.send(.didSelectVariant(card: card, queryType: store.content.queryType))

        case let .didShowCardAtIndex(index):
          store.send(.didShowVariant(index: index))
        }
      }
      .equatable()
    }
  }
}


/// The tokens this card makes.
private struct RelatedTokensSectionView: View {
  let store: StoreOf<CardDetailFeature>

  var body: some View {
    RelatedCardsSectionView(section: store.relatedTokens)
  }
}


/// The cards this one is usually played with.
private struct RelatedComboPiecesSectionView: View {
  let store: StoreOf<CardDetailFeature>

  var body: some View {
    RelatedCardsSectionView(section: store.relatedComboPieces)
  }
}


/// The other half of a meld pair.
private struct RelatedMeldPiecesSectionView: View {
  let store: StoreOf<CardDetailFeature>

  var body: some View {
    RelatedCardsSectionView(section: store.relatedMeldPieces)
  }
}


/// What this card melds into.
private struct RelatedMeldResultSectionView: View {
  let store: StoreOf<CardDetailFeature>

  var body: some View {
    RelatedCardsSectionView(section: store.relatedMeldResult)
  }
}


/// The body the four related-card rows share.
///
/// Handed the section it draws rather than reaching into the store for it: the
/// wrappers above exist precisely so that each read is recorded against a view
/// that depends on that one slice, and a shared view that took the store would
/// have to read all four to know which to show.
private struct RelatedCardsSectionView: View {
  let section: Content.SubContent?

  var body: some View {
    if let section, let cards = section.state.value {
      // Selection is not wired up for these rows yet; tapping one is a no-op
      // rather than a route that does not exist.
      HorizontalCardScrollView(
        title: section.title,
        subtitle: section.subtitle,
        cards: cards,
        isInitial: section.state.isInitial
      ) { _ in }
      .equatable()
    }
  }
}
