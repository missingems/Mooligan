import Browse
import ComposableArchitecture
import ScryfallKit

@Reducer struct Feature {
  @ObservableState struct State {
    var path = StackState<Path.State>()
  }
  
  @Reducer enum Path {
    case showSetDetail(Browse.Feature)
  }
  
  enum Action {
    case path(StackActionOf<Path>)
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      fatalError()
    }
    .forEach(\.path, action: \.path)
  }
}
