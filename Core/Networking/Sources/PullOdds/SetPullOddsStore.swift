import Dependencies
import Foundation
import SQLiteData

struct SetPullOddsStore: Sendable {
  @Dependency(\.defaultDatabase) private var database
  @Dependency(\.date.now) private var now

  func record(forSet setCode: String) async throws -> SetPullOddsRecord? {
    let id = setCode.lowercased()

    return try await database.read { connection in
      try #sql(
        """
        SELECT \(SetPullOddsRecord.columns) FROM "setPullOdds" WHERE "id" = \(bind: id) LIMIT 1
        """,
        as: SetPullOddsRecord.self
      )
      .fetchOne(connection)
    }
  }

  /// Whether a stored answer is recent enough to use without asking MTGJSON again.
  ///
  /// A set's booster configuration is fixed once it is printed, but MTGJSON does correct it now and
  /// then, most often in a new set's first weeks. A week is short enough to pick those corrections up
  /// and long enough that a set someone keeps browsing is downloaded about once a week.
  func isFresh(_ record: SetPullOddsRecord) -> Bool {
    now.timeIntervalSince1970 - Double(record.fetchedAt) < 60 * 60 * 24 * 7
  }

  func save(_ odds: SetPullOdds, forSet setCode: String) async throws {
    let record = try SetPullOddsRecord(setCode: setCode, odds: odds, fetchedAt: now)

    try await database.write { connection in
      try SetPullOddsRecord.upsert { record }.execute(connection)
    }
  }
}
