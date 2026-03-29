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
          do {
            // 1. Kick off both requests in parallel
            async let request1 = client.queryCards(
              .init(
                name: value.title,
                setCode: value.setCode?.set,
                collectorNumber: value.setCode?.code,
                page: 0,
                sortMode: .released,
                sortDirection: .auto
              )
            )
            
            async let request2 = client.queryCards(
              .init(
                name: value.title,
                collectorNumber: value.setCode?.code,
                page: 0,
                sortMode: .released,
                sortDirection: .auto
              )
            )
            
            // 2. Await both responses together
            let (response1, response2) = try await (request1, request2)
            
            let data1 = response1.data
            let data2 = response2.data
            
            // 3. Filter data2 without a Set to strictly preserve order.
            // We keep the card from data2 ONLY if data1 does NOT contain a card with the same ID.
            let filteredData2 = data2.filter { card2 in
              !data1.contains(where: { card1 in card1.id == card2.id })
            }
            
            // 4. Merge them (data1 goes first, followed by the strictly ordered, non-duplicate data2)
            let mergedData = data1 + filteredData2
            
            // 5. Build the data source
            let dataSource = CardDataSource(
              cards: mergedData,
              hasNextPage: response2.hasMore ?? false,
              total: response2.totalCards ?? 0
            )
            
            await send(.updateCards(dataSource))
          } catch {
            print("Failed to fetch cards: \(error)")
          }
        }
        
      case let .updateCards(value):
        state.dataSource = value
        return .none
      }
    }
  }
  
  public init() {}
}

public extension CardScannerFeature {
  @ObservableState struct State: Sendable, Equatable {
    var scannedResult: OCRCardScannedResult?
    var dataSource: CardDataSource?
    
    public init(scannedResult: OCRCardScannedResult?) {
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
