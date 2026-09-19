import Dependencies
import Foundation
import SQLiteData

/// Reads `DataFreshness` from the database, the image database's files, and MTGJSON.
public struct DataFreshnessReader: Sendable {
  @Dependency(\.defaultDatabase) private var database

  private let documentsDirectory: URL

  public init(
    documentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  ) {
    self.documentsDirectory = documentsDirectory
  }

  public func read() async throws -> DataFreshness {
    var freshness = try await database.read { connection in
      func date(_ stamp: Int64?) -> Date? {
        stamp.map { Date(timeIntervalSince1970: Double($0)) }
      }

      let pages = try CardPageRecord
        .select { ($0.id.count(), $0.fetchedAt.min(), $0.fetchedAt.max()) }
        .fetchOne(connection)
      let boosterOdds = try BoosterOddsRecord
        .select { ($0.id.count(), $0.fetchedAt.min(), $0.fetchedAt.max()) }
        .fetchOne(connection)
      let boosterBuilds = try BoosterOddsRecord
        .where { $0.mtgjsonVersion.isNot(nil) }
        .select { $0.mtgjsonVersion }
        .distinct()
        .fetchAll(connection)
      let pullOdds = try SetPullOddsRecord
        .select { ($0.id.count(), $0.fetchedAt.min(), $0.fetchedAt.max()) }
        .fetchOne(connection)
      let prices = try PriceHistoryRecord
        .select { ($0.id.count(), $0.fetchedAt.min(), $0.fetchedAt.max()) }
        .fetchOne(connection)
      let priceBuilds = try PriceHistoryRecord
        .where { $0.mtgjsonVersion.isNot(nil) }
        .select { $0.mtgjsonVersion }
        .distinct()
        .fetchAll(connection)

      return DataFreshness(
        catalog: try SyncStateRecord
          .where { $0.id.eq(BulkDataItem.defaultCardsType) }
          .fetchOne(connection),
        setsFetchedAt: date(try GameSetRecord.select { $0.fetchedAt.max() }.fetchOne(connection) ?? nil),
        cardPages: StoredDataset(
          count: pages?.0 ?? 0, oldest: date(pages?.1 ?? nil), newest: date(pages?.2 ?? nil)
        ),
        boosterOdds: StoredDataset(
          count: boosterOdds?.0 ?? 0,
          oldest: date(boosterOdds?.1 ?? nil),
          newest: date(boosterOdds?.2 ?? nil),
          builds: boosterBuilds.compactMap(\.self).sorted(by: >)
        ),
        pullOdds: StoredDataset(
          count: pullOdds?.0 ?? 0, oldest: date(pullOdds?.1 ?? nil), newest: date(pullOdds?.2 ?? nil)
        ),
        priceHistories: StoredDataset(
          count: prices?.0 ?? 0,
          oldest: date(prices?.1 ?? nil),
          newest: date(prices?.2 ?? nil),
          builds: priceBuilds.compactMap(\.self).sorted(by: >)
        )
      )
    }

    freshness.mtgjsonBuild = await MTGJSONBuild.shared.version()
    freshness.mtgjsonBuildAskedAt = await MTGJSONBuild.shared.lastAnswer()?.askedAt

    // The scanner's database is two files beside each other: the manifest it was patched up to,
    // and the database itself, written just before it.
    let manifestURL = documentsDirectory.appendingPathComponent("manifest.json")
    let databaseURL = documentsDirectory.appendingPathComponent("MTG_Hashes_Compressed.lzfse")
    freshness.cardImageHashes = (try? Data(contentsOf: manifestURL))
      .flatMap { try? JSONDecoder().decode(CardHashDatabaseManifest.self, from: $0) }
    freshness.cardImageHashesUpdatedAt = (try? FileManager.default.attributesOfItem(
      atPath: databaseURL.path
    ))?[.modificationDate] as? Date

    return freshness
  }
}
