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
            scan: .init()
          )
        ) {
          Feature()
        })
    }
  }
}

struct RootView: View {
  @Bindable var store: StoreOf<Feature>
  @Namespace var zoomAnimation
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  
  var body: some View {
    if horizontalSizeClass == .regular {
      // MARK: - Pure iPad Layout (3-Column Split View)
      NavigationSplitView {
        // 1. LEFT COLUMN (Sidebar / Tabs)
        // We use a custom binding to bridge TCA's non-optional state to the optional List selection.
        List(selection: Binding(
          get: { store.selectedTab },
          set: { newValue in
            if let newValue {
              $store.selectedTab.wrappedValue = newValue
            }
          }
        )) {
          ForEach(Feature.TabInfo.allCases) { info in
            Label(info.title, systemImage: info.systemIconName)
              .tag(info)
          }
        }
        .navigationTitle("Mooligan")
      } content: {
        // 2. MIDDLE COLUMN (Content / Sets List)
        switch store.selectedTab {
        case .sets:
          Browse.RootView(store: store.scope(state: \.sets, action: \.sets))
            .navigationTitle(Feature.TabInfo.sets.title)
          
        case .collection:
          Text(Feature.TabInfo.collection.title)
            .navigationTitle(Feature.TabInfo.collection.title)
          
        case .scan:
          CardScanner.RootView(store: store.scope(state: \.scan, action: \.scan))
            .navigationTitle(Feature.TabInfo.scan.title)
        }
      } detail: {
        // 3. RIGHT COLUMN (Detail / Query View)
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
          ContentUnavailableView(
            "Select an Item",
            systemImage: "sidebar.left",
            description: Text("Choose an item from the list to view its details.")
          )
        } destination: { destinationStore in
          switch destinationStore.case {
          case let .showCardPager(value):
            CardDetail.CardPagerView(store: value, zoomAnimation: zoomAnimation)
            
          case let .showCardDetail(value):
            CardDetail.RootView(store: value)
            
          case let .showSetDetail(value):
            Query.RootView(store: value, zoomAnimation: zoomAnimation)
          }
        }
      }
      .tint(DesignComponentsAsset.accentColor.swiftUIColor)
      
    } else {
      // MARK: - Standard iPhone Layout (Tab View)
      TabView(selection: $store.selectedTab) {
        ForEach(Feature.TabInfo.allCases) { info in
          Tab(info.title, systemImage: info.systemIconName, value: info) {
            switch info {
            case .sets:
              NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                Browse
                  .RootView(store: store.scope(state: \.sets, action: \.sets))
                  .navigationTitle(info.title)
                  .toolbarTitleDisplayMode(.inlineLarge)
              } destination: { destinationStore in
                switch destinationStore.case {
                case let .showCardPager(value):
                  CardDetail.CardPagerView(store: value, zoomAnimation: zoomAnimation)
                  
                case let .showCardDetail(value):
                  CardDetail.RootView(store: value)
                  
                case let .showSetDetail(value):
                  Query.RootView(store: value, zoomAnimation: zoomAnimation)
                }
              }
              
            case .collection:
              Text(info.title)
              
            case .scan:
              CardScanner.RootView(
                store: store.scope(state: \.scan, action: \.scan)
              )
              .toolbarColorScheme(.dark, for: .tabBar)
              .toolbarBackground(.black, for: .tabBar)
              .toolbarBackground(.visible, for: .tabBar)
            }
          }
        }
      }
      .tint(DesignComponentsAsset.accentColor.swiftUIColor)
    }
  }
}
