#if DEBUG
import ComposableArchitecture
import Foundation
import Networking

/// Deterministic, offline dependency wiring for UI tests.
///
/// `MooliganUITests` launches the app with `-uiTestMode`; this swaps every
/// network client for its in-memory mock and makes the bulk-sync / database
/// machinery inert, so a test never touches Scryfall or the on-disk database
/// and always sees the same data.
///
/// The whole file is `#if DEBUG`, and the mocks it references are themselves
/// `#if DEBUG`, so none of this reaches a Release build.
enum UITestSupport {
  static let launchArgument = "-uiTestMode"

  static var isActive: Bool {
    ProcessInfo.processInfo.arguments.contains(launchArgument)
  }

  /// Must run before the first `Store` is created (i.e. first line of
  /// `MooliganApp.init`).
  static func prepareIfNeeded() {
    guard isActive else { return }

    prepareDependencies {
      $0.gameSetRequestClient = MockGameSetRequestClient()
      $0.cardQueryRequestClient = MockCardQueryRequestClient(uiTestCorpus: 60, pageSize: 12)
      $0.cardDetailRequestClient = MockCardDetailRequestClient()

      $0.databasePreparer = InertDatabasePreparer()
      $0.bulkSyncScheduler = InertBulkSyncScheduler()
      $0.bulkDataSyncManager = InertBulkDataSyncManager()
      $0.bulkDataDownloader = UnavailableBulkDataDownloader()
      $0.bulkDataRequestClient = MockBulkDataRequestClient()
    }
  }
}
#endif
