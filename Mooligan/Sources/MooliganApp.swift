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
            
          case .scan:
            CardScanner.RootView(
              store: store.scope(
                state: \.scan,
                action: \.scan
              )
            )
            // 1. Force the tab items (icons/text) to use dark mode (white)
            .toolbarColorScheme(.dark, for: .tabBar)
            // 2. Force the tab bar background to be black
            .toolbarBackground(.black, for: .tabBar)
            // 3. Ensure the background stays visible, preventing it from
            // becoming transparent against the camera view
            .toolbarBackground(.visible, for: .tabBar)
          }
        }
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tint(DesignComponentsAsset.accentColor.swiftUIColor)
  }
}
