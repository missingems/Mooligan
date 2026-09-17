import Browse
import CardScanner
import CardDetail
import ComposableArchitecture
import DesignComponents
import PackOpening
import Query
import SwiftUI

struct RootView: View {
  @Bindable var store: StoreOf<Feature>
  @State private var width: CGFloat = 402.0
  
  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      browse(store.scope(state: \.sets, action: \.sets))
        .toolbar {
          menuItem
          ToolbarSpacer(.fixed, placement: .bottomBar)
          DefaultToolbarItem(kind: .search, placement: .bottomBar)
          ToolbarSpacer(.fixed, placement: .bottomBar)
          ToolbarItem(placement: .bottomBar) {
            Button {
              store.send(.menuItemSelected(.scan))
            } label: {
              Image(systemName: Feature.MenuItem.scan.systemIconName)
            }
            .accessibilityIdentifier("browse.scan")
          }
        }
    } destination: { destinationStore in
      switch destinationStore.case {
      case let .showCardPager(value):
        CardDetail.CardPagerView(store: value)
          .toolbar {
            menuItem
            ToolbarSpacer(.fixed, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
              CardDetail.CardPagerCarousel(store: value, width: max(0, width - 180.0))
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarSpacer(.fixed, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
              addButton
            }
          }
        
      case let .showCardDetail(value):
        CardDetail.RootView(store: value)
          .toolbar {
            menuItem
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
              addButton
            }
          }
        
      case let .showSetDetail(value):
        setDetail(value)
          .toolbar {
            menuItem
            ToolbarSpacer(.fixed, placement: .bottomBar)
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            ToolbarSpacer(.fixed, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
              filterButton(value)
            }
          }
      }
    }
    .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { width = $0 }
    .tint(DesignComponentsAsset.accentColor.swiftUIColor)
    .fullScreenCover(
      item: $store.scope(state: \.scan, action: \.scan)
    ) { scanStore in
      CardScanner.RootView(store: scanStore)
    }
    .fullScreenCover(
      item: $store.scope(state: \.packSession, action: \.packSession)
    ) { sessionStore in
      PackSessionView(store: sessionStore)
    }
    .sheet(isPresented: $store.isCollectionPresented) {
      ContentUnavailableView(
        Feature.MenuItem.collection.title,
        systemImage: Feature.MenuItem.collection.systemIconName,
        description: Text("Coming soon.")
      )
      .presentationDetents([.medium])
    }
  }
  
  @ToolbarContentBuilder private var menuItem: some ToolbarContent {
    ToolbarItem(placement: .bottomBar) {
      Menu {
        ForEach(Feature.MenuItem.allCases) { item in
          Button {
            store.send(.menuItemSelected(item))
          } label: {
            Label(item.title, systemImage: item.systemIconName)
          }
        }
      } label: {
        Image(systemName: "line.3.horizontal")
      }
      .accessibilityIdentifier("toolbar.menu")
    }
  }
  
  private func browse(_ browseStore: StoreOf<BrowseFeature>) -> some View {
    @Bindable var sets = browseStore
    
    return Browse.RootView(store: sets)
      .navigationTitle(Feature.MenuItem.sets.title)
      .toolbarTitleDisplayMode(.inlineLarge)
      .searchable(text: $sets.query)
  }
  
  private func setDetail(_ queryStore: StoreOf<QueryFeature>) -> some View {
    @Bindable var query = queryStore
    
    return Query.RootView(store: query)
      .searchable(text: $query.query.name, prompt: Text(query.searchPrompt))
  }
  
  private var addButton: some View {
    Button {
    } label: {
      Image(systemName: "plus")
    }
    .accessibilityIdentifier("cardDetail.add")
  }
  
  private func filterButton(_ queryStore: StoreOf<QueryFeature>) -> some View {
    @Bindable var query = queryStore
    
    return Button {
      withAnimation(.smooth) {
        query.isFilterExpanded.toggle()
      }
    } label: {
      Image(systemName: query.isFilterExpanded ? "xmark" : "line.3.horizontal.decrease")
        .contentTransition(.symbolEffect(.replace))
    }
    .accessibilityIdentifier("setDetail.filter.toggle")
  }
}
