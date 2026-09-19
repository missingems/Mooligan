import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct InformationSectionView: View {
  let store: StoreOf<CardDetailFeature>
  let content: Content
  let faceDirection: MagicCardFaceDirection?

  /// The explanations on show, in a store of their own: see `InsightPagerFeature`.
  @State private var insight: StoreOf<InsightPagerFeature>?

  var body: some View {
    // One view to hang the cover on: the row's body is two views, and a modifier on it would be
    // applied to each.
    VStack(spacing: 0) {
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
        setIconURL: store.setIconURL,
        pullOdds: store.pullOdds.odds,
        stickerTilt: content.card.id.stickerTilt,
        onSelect: present
      )
    }
    .fullScreenCover(item: $insight) { insight in
      InsightPagerView(store: insight)
        .presentationBackground(.clear)
    }
  }

  private func present(_ widget: InformationWidget, row: [InformationWidget]) {
    // Presented without the cover's slide up: the explanation fades itself in once it is built.
    var instant = Transaction()
    instant.disablesAnimations = true
    withTransaction(instant) {
      insight = Store(
        initialState: InsightPagerFeature.State(
          widgets: row,
          selected: widget,
          card: content.card,
          faceDirection: faceDirection
        )
      ) {
        InsightPagerFeature()
      }
    }
  }
}
