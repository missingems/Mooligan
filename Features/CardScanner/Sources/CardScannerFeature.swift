import ComposableArchitecture
import ScryfallKit
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
        guard state.scannedResult != result else {
          return .none
        }
        
        state.scannedResult = result
        
        return .run { send in
          await send(
            .fetchCard(
              withSetCode: .withSetCode(result),
              withoutSetCode: .withoutSetCode(result)
            )
          )
        }
        
      case let .fetchCard(query1, query2):
        guard let query1, let query2 else {
          return .none
        }
        
        return .run { [query1, query2] send in
          async let withSetCodeRequest = client.queryCards(query1)
          async let withoutSetCodeRequest = client.queryCards(query2)
          
          let value = try? await (withSetCodeRequest, withoutSetCodeRequest)
          
          let data1: [Card] = value?.0.data ?? []
          let data2: [Card] = value?.1.data ?? []
          
          let filteredData2 = data2.filter { card2 in
            !data1.contains(where: { card1 in card1.id == card2.id })
          }

          let mergedData = data1 + filteredData2

          let dataSource = CardDataSource(
            cards: mergedData,
            hasNextPage: value?.1.hasMore ?? false,
            total: value?.1.totalCards ?? 0
          )

          await send(
            .updateCards(
              dataSource,
              withSetCode: query1,
              withoutSetCode: query2
            )
          )
        }
        
      case let .updateCards(value, query1, query2):
        state.dataSource = value
        state.queryWithSetCode = query1
        state.queryWithoutSetCode = query2
        return .none
        
      case let .loadMoreCardsIfNeeded(displayingIndex):
        guard
          displayingIndex == (state.dataSource?.cardDetails.count ?? 1) - 1,
          state.dataSource?.hasNextPage == true
        else {
          return .none
        }
        
        let queryWithSetCode = state.queryWithSetCode?.next()
        let queryWithoutSetCode = state.queryWithoutSetCode?.next()
        
        return .run { send in
          await send(
            .fetchCard(
              withSetCode: queryWithSetCode,
              withoutSetCode: queryWithoutSetCode
            )
          )
        }
      }
    }
  }
  
  public init() {}
}

public extension CardScannerFeature {
  @ObservableState struct State: Sendable, Equatable {
    var scannedResult: OCRCardScannedResult?
    var dataSource: CardDataSource?
    var queryWithSetCode: SearchQuery?
    var queryWithoutSetCode: SearchQuery?
    
    public init(scannedResult: OCRCardScannedResult?) {
      self.scannedResult = scannedResult
    }
  }
  
  enum Action: Equatable, Sendable {
    case didScan(OCRCardScannedResult)
    case updateScanResult(OCRCardScannedResult)
    case fetchCard(withSetCode: SearchQuery?, withoutSetCode: SearchQuery?)
    case updateCards(CardDataSource, withSetCode: SearchQuery, withoutSetCode: SearchQuery)
    case loadMoreCardsIfNeeded(displayingIndex: Int)
  }
}

extension SearchQuery {
  static func withSetCode(_ result: OCRCardScannedResult) -> SearchQuery {
    return SearchQuery(
      name: result.title,
      cardType: [.all],
      setCode: result.setCode?.set,
      collectorNumber: result.setCode?.code,
      page: 0,
      sortMode: .released,
      sortDirection: .auto
    )
  }
  
  static func withoutSetCode(_ result: OCRCardScannedResult) -> SearchQuery {
    return SearchQuery(
      name: result.title,
      cardType: [.all],
      page: 0,
      sortMode: .released,
      sortDirection: .auto
    )
  }
}
