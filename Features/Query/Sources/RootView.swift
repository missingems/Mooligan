import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  public let queryType: QueryType
  
  public var body: some View {
    QueryView(store: Store(initialState: Feature.State(queryType: queryType), reducer: {
      Feature(client: ScryfallClient(networkLogLevel: .minimal))
    }))
  }
  
  public init(queryType: QueryType) {
    self.queryType = queryType
  }
}
