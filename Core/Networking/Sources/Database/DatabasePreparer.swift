import ComposableArchitecture

public protocol DatabasePreparing: Sendable {
  /// Opens the database and brings its schema up to date.
  ///
  /// Deliberately synchronous, and deliberately on the main thread during
  /// launch, which Xcode's thread performance checker reports as "Performing
  /// I/O on the main thread can cause hangs". Making it async looked like the
  /// obvious fix and broke the app twice over: `defaultDatabase` was then unset
  /// when the first screen read it, so SQLiteData handed out a blank in-memory
  /// database and migrated *that*; and the background-task registration that
  /// follows this call got pushed past the end of launch, which `BGTaskScheduler`
  /// answers by throwing "No launch handler registered".
  ///
  /// Moving this off the main thread needs the app to have a real "database is
  /// ready" gate that every read waits on, not just an `await` here. Until
  /// there is one, a warning at launch is the better trade.
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
