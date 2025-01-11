import Browse
import CardDetail
import ComposableArchitecture
import Foundation
import DesignComponents
import Query
import SwiftUI

@main
struct MooliganApp: App {
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      RootView(store: Store(initialState: Feature.State(sets: .init(selectedSet: nil, sets: []))) {
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
            } destination: { store in
              switch store.case {
              case let .showSetDetail(value):
                Query.RootView(store: value)
                
              case let .showCardDetail(value):
                CardDetail.RootView(store: value)
              }
            }
          }
        }
      }
    }
    .tint(DesignComponentsAsset.accentColor.swiftUIColor)
  }
}
