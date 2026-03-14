import ComposableArchitecture
import DesignComponents
import Networking

@Reducer public struct CardScannerFeature: Sendable {
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .scan:
        return .none
        
      case let .didScan(result):
        guard result != state.scannedResult else {
          return .none
        }
        
        return .run { send in
          await send(.updateScanResult(result))
        }
        
      case let .updateScanResult(result):
        state.scannedResult = result
        return .none
        
      case .fetchCard:
        return .none
        
      case .updateCards(_):
        return .none
      }
    }
    ._printChanges()
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
  
  enum Action: Equatable, Sendable {
    case scan
    case didScan(OCRCardScannedResult)
    case updateScanResult(OCRCardScannedResult)
    case fetchCard(title: String, setCode: String)
    case updateCards(CardDataSource?)
  }
}
