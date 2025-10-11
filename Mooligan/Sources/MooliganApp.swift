import Browse
import CardDetail
import ComposableArchitecture
import Foundation
import DesignComponents
import Networking
import Query
import SwiftUI

@main
struct MooliganApp: App {
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      RootView(store: Store(initialState: Feature.State(sets: .init(selectedSet: nil))) {
        Feature()
      })
    }
  }
}

struct RootView: View {
  @Bindable var store: StoreOf<Feature>
  
  var body: some View {
    TabView {
      ForEach(Feature.TabInfo.allCases) { info in
        Tab(info.title, systemImage: info.systemIconName) {
          switch info {
          case .sets:
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
              Browse
                .RootView(store: store.scope(state: \.sets, action: \.sets))
                .navigationTitle(info.title)
                .toolbarTitleDisplayMode(.inlineLarge)
            } destination: { store in
              switch store.case {
              case let .showCardDetail(value):
                CardDetail.RootView(store: value)
                
              case let .showSetDetail(value):
                Query.RootView(store: value)
              }
            }
            
          case .collection:
            Text(info.title)
          }
        }
      }
      
      Tab(role: .search) {
        Text("Search")
      }
    }
    .toolbarVisibility(.visible, for: .tabBar)
    .tint(DesignComponentsAsset.accentColor.swiftUIColor)
  }
}
