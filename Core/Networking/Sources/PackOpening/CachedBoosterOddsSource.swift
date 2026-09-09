import Dependencies
import Foundation
import ScryfallKit
import SQLiteData

/// Booster odds, worked out once and then read from disk.
///
/// A set's booster configuration is fixed when the set is printed — the sheets
/// and their weights do not change afterwards — but recovering it meant
/// downloading and parsing a two-to-six megabyte MTGJSON set file, every
/// session, for three numbers. Worse, MTGJSON's serving is uneven: some set
/// files stall part-way through and never finish, which is what left packs
/// sitting on "deciding what is in it".
///
/// So the answer is worked out at most once per set per MTGJSON build and kept
/// in the app's database. After that a pack opens with no network at all, works
/// offline, and survives relaunches.
///
/// Only *real* odds are written. A set that fell back — because MTGJSON has no
/// entry for it, because its sheets are a shape the parser doesn't recognise,
/// or because the download stalled — is left uncached on disk so that a
/// transient failure doesn't pin it to approximate odds for ever. The upstream
/// source still remembers it for the rest of the session, so nothing hammers a
/// set that has already failed once.
public struct CachedBoosterOddsSource: BoosterOddsSource {
  private let upstream: any BoosterOddsSource
  private let build: MTGJSONBuild

  public init(upstream: any BoosterOddsSource, session: URLSession? = nil) {
    self.upstream = upstream
    build = MTGJSONBuild(session: session)
  }

  public func odds(forSet setCode: String, kind: BoosterPackKind) async -> BoosterPackOdds {
    let store = BoosterOddsStore()

    // What build the stored answer would have to match to still be trusted.
    // Nil means MTGJSON could not be reached to ask — in which case whatever is
    // on disk is used regardless, because a network blip is a much worse reason
    // to re-download six megabytes than a stale row is to serve slightly old
    // odds.
    let currentVersion = await build.version()

    if let stored = try? await store.odds(forSet: setCode, kind: kind),
      currentVersion == nil || stored.mtgjsonVersion == nil
        || stored.mtgjsonVersion == currentVersion,
      let odds = stored.odds
    {
      return odds
    }

    let odds = await upstream.odds(forSet: setCode, kind: kind)
    guard odds != .fallback else { return odds }

    try? await store.save(odds, forSet: setCode, kind: kind, mtgjsonVersion: currentVersion)
    return odds
  }
}

// MARK: - Storage

struct BoosterOddsStore: Sendable {
  @Dependency(\.defaultDatabase) private var database
  @Dependency(\.date.now) private var now

  func odds(forSet setCode: String, kind: BoosterPackKind) async throws -> BoosterOddsRecord? {
    let id = BoosterOddsRecord.identifier(setCode: setCode, kind: kind)

    return try await database.read { connection in
      try #sql(
        """
        SELECT \(BoosterOddsRecord.columns) FROM "boosterOdds" WHERE "id" = \(bind: id) LIMIT 1
        """,
        as: BoosterOddsRecord.self
      )
      .fetchOne(connection)
    }
  }

  func save(
    _ odds: BoosterPackOdds,
    forSet setCode: String,
    kind: BoosterPackKind,
    mtgjsonVersion: String?
  ) async throws {
    let record = try BoosterOddsRecord(
      setCode: setCode,
      kind: kind,
      odds: odds,
      mtgjsonVersion: mtgjsonVersion,
      fetchedAt: now
    )

    try await database.write { connection in
      try BoosterOddsRecord.upsert { record }.execute(connection)
    }
  }
}

// MARK: - Build stamp

/// MTGJSON's current build version, asked for once per launch.
///
/// `Meta.json` is a hundred-odd bytes and answers in well under a second, which
/// makes it a cheap way to find out whether anything stored is still current
/// without touching a set file. A failure is not an error: it returns nil, and
/// the caller treats stored odds as good.
actor MTGJSONBuild {
  private let session: URLSession
  private var cached: String??

  init(session: URLSession? = nil) {
    if let session {
      self.session = session
    } else {
      let configuration = URLSessionConfiguration.default
      configuration.timeoutIntervalForRequest = 5
      configuration.timeoutIntervalForResource = 5
      self.session = URLSession(configuration: configuration)
    }
  }

  func version() async -> String? {
    if let cached { return cached }

    let value = await fetch()
    cached = .some(value)
    return value
  }

  private func fetch() async -> String? {
    guard let url = URL(string: "https://mtgjson.com/api/v5/Meta.json") else { return nil }

    guard
      let (data, response) = try? await session.data(from: url),
      (response as? HTTPURLResponse)?.statusCode == 200,
      let meta = try? JSONDecoder().decode(MTGJSONMetaFile.self, from: data)
    else { return nil }

    return meta.data.version
  }
}

private struct MTGJSONMetaFile: Decodable {
  struct Meta: Decodable {
    let version: String?
  }

  let data: Meta
}
