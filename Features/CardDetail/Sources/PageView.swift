import ComposableArchitecture
import DesignComponents
import VariableBlur
import ScryfallKit
import SwiftUI
import Networking

public struct PageView: View {
  @State private var safeAreaTopInset: CGFloat?
  @Bindable private var store: StoreOf<PageFeature>
  
  public init(store: StoreOf<PageFeature>) {
    self.store = store
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
      .scrollPosition(id: $store.dataSource.focusedCard)
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
      proxy.safeAreaInsets.top
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
