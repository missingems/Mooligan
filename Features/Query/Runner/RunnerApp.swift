import ComposableArchitecture
import Networking
import Query
import ScryfallKit
import SwiftUI

@main
struct RunnerApp: App {
  var body: some Scene {
    let set = MockGameSetRequestClient.mockSets[0]

    WindowGroup {
      NavigationStack {
        Query.RootView(
          store: Store(
            initialState: QueryFeature.State(
              mode: .placeholder,
              queryType: .querySet(
                set,
                SearchQuery(
                  setCode: set.code,
                  page: 1,
                  sortMode: .name,
                  sortDirection: .asc
                )
              )
            )
          ) {
            QueryFeature()
          }
        )
      }
    }
  }
}
