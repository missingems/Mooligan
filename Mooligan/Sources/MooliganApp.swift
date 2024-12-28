import Browse
import ComposableArchitecture
import DesignComponents
import SwiftUI

@main
struct MooliganApp: App {
  @Bindable var store: StoreOf<Feature>
  
  init() {
    DesignComponents.Main().setup()
    
    store = .init(initialState: Feature.State(), reducer: {
      Feature()
    })
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        Browse.RootView()
      }
      
      
    }
  }
}
