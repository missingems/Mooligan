import ComposableArchitecture
import DesignComponents
import Networking

@Reducer public struct CardScannerFeature: Sendable {
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding(\.scannedResult):
        print(state.scannedResult)
        return .none
      case .binding:
        return .none
      case .scan:
        return .none
      case .didScan(title: let title, setCode: let setCode):
        return .none
      case .fetchCard(title: let title, setCode: let setCode):
        return .none
      case .updateCards(_):
        return .none
      }
    }._printChanges()
  }
  
  public init() {}
}

public extension CardScannerFeature {
  @ObservableState struct State: Sendable, Equatable {
    var scannedResult: OCRCardScannedResult
    public init(scannedResult: OCRCardScannedResult) {
      self.scannedResult = scannedResult
    }
  }
  
  enum Action: Equatable, Sendable, BindableAction {
    case binding(BindingAction<State>)
    case scan
    case didScan(title: String, setCode: String)
    case fetchCard(title: String, setCode: String)
    case updateCards(CardDataSource?)
  }
}
