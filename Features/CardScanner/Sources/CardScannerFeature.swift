import ComposableArchitecture
import Networking

@Reducer public struct CardScannerFeature: Sendable {
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      return .none
    }
  }
  
  public init() {}
}

public extension CardScannerFeature {
  @ObservableState struct State: Sendable, Equatable {
    
  }
  
  enum Action: Equatable, Sendable {
    case scan
    case didScan(title: String, setCode: String)
    case fetchCard(title: String, setCode: String)
    case updateCards(CardDataSource?)
  }
}
