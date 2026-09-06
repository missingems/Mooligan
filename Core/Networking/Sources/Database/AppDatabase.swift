import Dependencies
import Foundation
import OSLog
import SQLiteData

let databaseLogger = Logger(subsystem: "com.missingems.mooligan", category: "Database")

public func appDatabase() throws -> any DatabaseWriter {
  @Dependency(\.context) var context

  var configuration = Configuration()

#if DEBUG
  configuration.prepareDatabase { connection in
    connection.trace(options: .profile) { event in
      if context == .preview {
        print("\(event.expandedDescription)")
      } else {
        databaseLogger.debug("\(event.expandedDescription)")
      }
    }
  }
#endif

  let database = try defaultDatabase(configuration: configuration)
  databaseLogger.info("open '\(database.path)'")
  try migrator().migrate(database)
  return database
}

public func prepareAppDatabase() {
  prepareDependencies {
    if let database = (try? appDatabase()) ?? (try? inMemoryDatabase()) {
      $0.defaultDatabase = database
    }
  }
}

public func inMemoryDatabase() throws -> any DatabaseWriter {
  let database = try DatabaseQueue()
  try migrator().migrate(database)
  return database
}

public func migrator() -> DatabaseMigrator {
  var migrator = DatabaseMigrator()

#if DEBUG
  migrator.eraseDatabaseOnSchemaChange = true
#endif

  migrator.registerMigration("v1.createSchema") { connection in
    try #sql(
      """
      CREATE TABLE "cards" (
        "id" BLOB NOT NULL PRIMARY KEY,
        "oracleID" TEXT,
        "name" TEXT NOT NULL,
        "setCode" TEXT NOT NULL,
        "setID" BLOB,
        "collectorNumber" TEXT NOT NULL,
        "collectorNumberSort" TEXT NOT NULL,
        "releasedAt" TEXT NOT NULL,
        "rarityRank" INTEGER NOT NULL,
        "colorRank" INTEGER NOT NULL,
        "cmc" REAL,
        "typeLine" TEXT,
        "colorIdentity" TEXT NOT NULL,
        "usd" REAL,
        "isDigital" INTEGER NOT NULL,
        "isPaper" INTEGER NOT NULL,
        "card" BLOB NOT NULL,
        "ingestedAt" INTEGER NOT NULL,
        "source" INTEGER NOT NULL
      ) STRICT
      """
    )
    .execute(connection)

    try #sql(#"CREATE INDEX "cards_set" ON "cards"("setCode", "collectorNumberSort")"#).execute(connection)
    try #sql(#"CREATE INDEX "cards_name" ON "cards"("name")"#).execute(connection)
    try #sql(#"CREATE INDEX "cards_oracleID" ON "cards"("oracleID")"#).execute(connection)

    try #sql(
      """
      CREATE TABLE "gameSets" (
        "id" BLOB NOT NULL PRIMARY KEY,
        "code" TEXT NOT NULL,
        "name" TEXT NOT NULL,
        "releasedAt" TEXT,
        "parentSetCode" TEXT,
        "cardCount" INTEGER NOT NULL,
        "isDigital" INTEGER NOT NULL,
        "payload" BLOB NOT NULL,
        "fetchedAt" INTEGER NOT NULL
      ) STRICT
      """
    )
    .execute(connection)

    try #sql(#"CREATE UNIQUE INDEX "gameSets_code" ON "gameSets"("code")"#).execute(connection)

    try #sql(
      """
      CREATE TABLE "cardPages" (
        "id" TEXT NOT NULL PRIMARY KEY,
        "queryKey" TEXT NOT NULL,
        "page" INTEGER NOT NULL,
        "cardIDs" BLOB NOT NULL,
        "hasMore" INTEGER NOT NULL,
        "totalCards" INTEGER NOT NULL,
        "fetchedAt" INTEGER NOT NULL
      ) STRICT
      """
    )
    .execute(connection)

    try #sql(#"CREATE INDEX "cardPages_queryKey" ON "cardPages"("queryKey")"#).execute(connection)

    try #sql(
      """
      CREATE TABLE "syncState" (
        "id" TEXT NOT NULL PRIMARY KEY,
        "remoteUpdatedAt" TEXT,
        "etag" TEXT,
        "lastCheckedAt" INTEGER,
        "lastIngestedAt" INTEGER,
        "ingestedCardCount" INTEGER NOT NULL,
        "status" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(connection)
  }

  return migrator
}
