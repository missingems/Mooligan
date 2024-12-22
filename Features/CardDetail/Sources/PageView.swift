import ComposableArchitecture
import DesignComponents
import VariableBlur
import SwiftUI
import Networking

public struct PageView<Client: MagicCardDetailRequestClient>: View {
  @State var safeAreaTopInset: CGFloat?
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
    ZStack(alignment: .top) {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 0) {
          ForEach(
            Array(store.scope(state: \.cards, action: \.cards))
          ) { store in
            CardDetailView(store: store).containerRelativeFrame(.horizontal)
          }
        }
        .scrollTargetLayout()
      }
      .scrollPosition(id: $store.currentDisplayingCard)
      .scrollTargetBehavior(.paging)
      .background(.black)
      .zIndex(0)
      
      if let safeAreaTopInset {
        VariableBlurView(direction: .blurredTopClearBottom)
          .frame(height: safeAreaTopInset + 5)
          .ignoresSafeArea()
          .zIndex(1)
      }
    }
    .onGeometryChange(for: CGFloat.self, of: { proxy in
      return proxy.safeAreaInsets.top
    }, action: { newValue in
      safeAreaTopInset = newValue
    })
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
}
