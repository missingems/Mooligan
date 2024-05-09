import ComposableArchitecture
import SwiftUI
import Networking

@Reducer
struct Feature<Client: GameSetRequestClient> {
  let client: Client
  
  @ObservableState
  struct State: Equatable {
    var isLoading: Bool = false
    var selectedSet: Client.Model? = nil
    var sets: [Client.Model] = []
    var title = String(localized: "Sets")
    
    func getSetRowViewModel(
      at index: Int,
      colorScheme: ColorScheme
    ) -> SetRow.ViewModel {
      SetRow.ViewModel(
        set: sets[index],
        selectedSet: selectedSet,
        index: index,
        colorScheme: colorScheme
      )
    }
  }
  
  enum Action: Equatable {
    case didSelectSet(index: Int)
    case fetchSets
    case viewAppeared
    case updateSets([Client.Model])
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didSelectSet(index):
        state.selectedSet = state.sets[index]
        return .none
        
      case .fetchSets:
        state.isLoading = true
        
        return .run { send in
          let objectList = try await client.getAllSets()
          await send(.updateSets(objectList))
        }
        
      case .viewAppeared:
        return .run { send in
          await send(.fetchSets)
        }
        
      case let .updateSets(value):
        state.isLoading = false
        state.sets = value
        return .none
      }
    }
    ._printChanges(.actionLabels)
  }
}
