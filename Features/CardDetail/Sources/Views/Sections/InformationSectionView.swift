import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct InformationSectionView: View {
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
