import ComposableArchitecture

public extension DependencyValues {
  var cardImageHashSyncManager: any CardImageHashSyncManagable {
    get { self[CardImageHashSyncManagerKey.self] }
    set { self[CardImageHashSyncManagerKey.self] = newValue }
  }
}
