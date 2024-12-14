import ComposableArchitecture
import DesignComponents
import VariableBlur
import SwiftUI
import Networking

public struct PageView<Client: MagicCardDetailRequestClient>: View {
  @Bindable var store: StoreOf<PageFeature<Client>>
  
  public init(client: Client, cards: [Client.MagicCardModel]) {
    self.store = Store(
      initialState: PageFeature<Client>.State(cards: cards), reducer: {
        PageFeature<Client>(client: client)
      }
    )
  }
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      ZStack(alignment: .top) {
        LazyHStack(alignment: .top, spacing: 0) {
          let stores = Array(store.scope(state: \.cards, action: \.cards))
          ForEach(
            stores.indices, id: \.self
          ) { index in
            CardDetailView(store: stores[index])
              .containerRelativeFrame(.horizontal)
              .id(index)
          }
        }
        .scrollTargetLayout()
        
        VariableBlurView(direction: .blurredTopClearBottom).frame(height: 105).ignoresSafeArea()
      }
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Button {
            store.send(.addTapped)
          } label: {
            Image(systemName: "plus").fontWeight(.semibold)
          }
          .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
          
          Button {
            store.send(.shareTapped)
          } label: {
            Image(systemName: "square.and.arrow.up").fontWeight(.semibold)
          }
          .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
        }
      }
    }
    .scrollPosition(id: $store.currentDisplayingCard)
    .scrollTargetBehavior(.paging)
    .background(.black)
  }
}
