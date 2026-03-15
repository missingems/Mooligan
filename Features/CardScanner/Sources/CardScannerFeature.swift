import ComposableArchitecture
import DesignComponents
import Networking

@Reducer public struct CardScannerFeature: Sendable {
  @Dependency(\.cardQueryRequestClient) var client
  
  public var body: some ReducerOf<Self> {
    Reduce {state, action in
      switch action {
      case let .didScan(result):
        guard result != state.scannedResult else {
          return .none
        }
        
        return .run { send in
          await send(.updateScanResult(result))
        }
        
      case let .updateScanResult(result):
        state.scannedResult = result
        
        return .run { send in
          await send(.fetchCard(result))
        }
        
      case let .fetchCard(value):
        return .run { [value] send in
          let results = try await client.queryCards(
            .init(
              name: value.title,
              setCode: value.setCode?.set,
              collectorNumber: value.setCode?.code,
              page: 0,
              sortMode: .released,
              sortDirection: .auto
            )
          )
          
          let dataSource = CardDataSource(
            cards: results.data,
            hasNextPage: results.hasMore ?? false,
            total: results.totalCards ?? 0
          )
          
          await send(.updateCards(dataSource))
        }
        
      case let .updateCards(value):
        state.dataSource = value
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
    var dataSource: CardDataSource?
    
    public init(scannedResult: OCRCardScannedResult) {
      self.scannedResult = scannedResult
    }
  }
  
  enum Action: Equatable, Sendable {
    case didScan(OCRCardScannedResult)
    case updateScanResult(OCRCardScannedResult)
    case fetchCard(OCRCardScannedResult)
    case updateCards(CardDataSource)
  }
}
