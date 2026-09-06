import ComposableArchitecture

public protocol DatabasePreparing: Sendable {
  func prepare()
}

public struct AppDatabasePreparer: DatabasePreparing {
  public init() {}

  public func prepare() {
    prepareAppDatabase()
  }
}

#if DEBUG
public struct InertDatabasePreparer: DatabasePreparing {
  public init() {}
  public func prepare() {}
}
#endif

public enum DatabasePreparerKey: DependencyKey {
  public static let liveValue: any DatabasePreparing = AppDatabasePreparer()
#if DEBUG
  public static let previewValue: any DatabasePreparing = InertDatabasePreparer()
  public static let testValue: any DatabasePreparing = InertDatabasePreparer()
#endif
}

public extension DependencyValues {
  var databasePreparer: any DatabasePreparing {
    get { self[DatabasePreparerKey.self] }
    set { self[DatabasePreparerKey.self] = newValue }
  }
}
