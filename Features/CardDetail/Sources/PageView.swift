import ComposableArchitecture
import DesignComponents
import VariableBlur
import SwiftUI
import Networking

public struct PageView<Client: MagicCardDetailRequestClient>: View {
  let store: StoreOf<PageFeature<Client>>
  
  public init(client: Client, cards: [Client.MagicCardModel]) {
    self.store = Store(
      initialState: PageFeature<Client>.State(cards: cards), reducer: {
        PageFeature<Client>(client: client)
      }
    )
  }
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top, spacing: 0) {
        ForEach(
          Array(store.scope(state: \.cards, action: \.cards))
        ) { store in
          CardDetailView(store: store)
            .containerRelativeFrame(.horizontal)
            .navigationTitle(" ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(self.store.navigationBarBackgroundVisibility, for: .navigationBar)
            .toolbarBackground(.clear, for: .navigationBar)
            .animation(.default, value: self.store.navigationBarBackgroundVisibility)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .background(.black)
  }
}
