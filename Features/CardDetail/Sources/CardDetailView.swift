import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct CardDetailView<Client: MagicCardDetailRequestClient>: View {
  let store: StoreOf<Feature<Client>>
  
  var body: some View {
    GeometryReader { proxy in
      if proxy.size.width > 0 {
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            HeaderView(
              imageURL: store.content.imageURL,
              isFlippable: false,
              orientation: .portrait,
              rotation: 0
            )
            TitleView(
              name: store.content.name,
              manaCosts: store.content.manaCost
            )
            TypelineView(store.content.typeline)
            DescriptionView(store.content.text)
            FlavorView(store.content.flavorText)
            InfoView(
              power: store.content.power,
              toughness: store.content.toughness,
              loyaltyCounters: store.content.loyalty,
              manaValue: store.content.manaValue,
              collectorNumber: store.content.collectorNumber,
              colorIdentity: store.content.colorIdentity,
              setCode: store.content.setCode,
              setIconURL: store.content.setIconURL
            )
            LegalityView(
              title: store.content.legalityLabel,
              displayReleaseDate: store.content.displayReleasedDate,
              legalities: store.content.legalities
            )
          }
        }
        .background { Color(.secondarySystemBackground).ignoresSafeArea() }
      }
    }
    .task {
      store.send(.viewAppeared(initialAction: store.start))
    }
  }
}
