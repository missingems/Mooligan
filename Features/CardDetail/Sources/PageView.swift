import ComposableArchitecture
import DesignComponents
import VariableBlur
import SwiftUI
import Networking

public struct PageView<Client: MagicCardDetailRequestClient>: View {
  @Bindable var store: StoreOf<PageFeature<Client>>
  
  public init(client: Client, cards: [Client.MagicCardModel]) {
    store = Store(
      initialState: PageFeature<Client>.State(cards: cards),
      reducer: {
        PageFeature<Client>(client: client)
      }
    )
  }
  
  public var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .top) {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top, spacing: 0) {
            ForEach(
              Array(store.scope(state: \.cards, action: \.cards))
            ) { store in
              CardDetailView(geometryProxy: proxy, store: store).containerRelativeFrame(.horizontal)
            }
          }
          .scrollTargetLayout()
        }
        .zIndex(0)
        
        VariableBlurView(direction: .blurredTopClearBottom).frame(height: proxy.safeAreaInsets.top).ignoresSafeArea()
          .zIndex(1)
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
      .scrollPosition(id: $store.currentDisplayingCard)
      .scrollTargetBehavior(.paging)
      .background(.black)
    }
  }
}

