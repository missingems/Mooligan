import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  public let queryType: QueryType
  
  public var body: some View {
    QueryView(
      store: Store(
        initialState: Feature.State(
          mode: .placeholder(numberOfDataSource: 10),
          queryType: .set(MockGameSetRequestClient.mockSets[0], page: 1),
          selectedCard: nil
        ),
        reducer: {
          Feature()
        }
      )
    )
  }
  
  public init(queryType: QueryType) {
    self.queryType = queryType
  }
}
