import Browse
import CardScanner
import CardDetail
import ComposableArchitecture
import Foundation
import DesignComponents
import Networking
import PackOpening
import Query
import SwiftUI

@main
struct MooliganApp: App {
  private let store: StoreOf<Feature>

  init() {
    #if DEBUG
    UITestSupport.prepareIfNeeded()
    #endif

    DesignComponents.Main().setup()

    let store = Store(initialState: Feature.State()) { Feature() }
    store.send(.setup)
    self.store = store
  }
  
  var body: some Scene {
    WindowGroup {
      RootView(store: store)
        .task {
          await store.send(.bulkSync(.task)).finish()
        }
    }
    .backgroundTask(.urlSession(BackgroundBulkDataDownloader.sessionIdentifier)) {
      await store.send(.bulkSync(.syncRequested(force: true))).finish()
    }
  }
}
