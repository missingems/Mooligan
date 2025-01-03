import Browse
import ComposableArchitecture
import DesignComponents
import Query
import SwiftUI

@main
struct MooliganApp: App {
  @Bindable var store: StoreOf<Feature>
  
  init() {
    DesignComponents.Main().setup()
    
    store = Store(initialState: Feature.State()) {
      Feature()
    }
  }
  
  var body: some Scene {
    WindowGroup {
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
                }
              }
            }
          }
        }
      }
      .tint(DesignComponentsAsset.accentColor.swiftUIColor)
    }
  }
}
