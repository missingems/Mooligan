import Browse
import CardScanner
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
      RootView(
        store: Store(
          initialState: Feature.State(
            sets: .init(selectedSet: nil),
            scan: .init(scannedResult: nil)
          )
        ) {
          Feature()
        })
    }
  }
}

struct RootView: View {
  @Bindable var store: StoreOf<Feature>
  
  var body: some View {
    // 1. Bind to the store's selection
    TabView(selection: $store.selectedTab) {
      ForEach(Feature.TabInfo.allCases) { info in
        // 2. Pass 'value: info' so the binding maps correctly
        Tab(info.title, systemImage: info.systemIconName, value: info) {
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
            
          case .scan:
            CardScanner.RootView(
              store: store.scope(
                state: \.scan,
                action: \.scan
              )
            )
            .toolbarColorScheme(.dark, for: .tabBar)
            .toolbarBackground(.black, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
          }
        }
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tint(DesignComponentsAsset.accentColor.swiftUIColor)
  }
}
