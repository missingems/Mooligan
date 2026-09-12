import Foundation
import SQLiteData

/// One set's booster odds for one product, kept so they are worked out once and
/// then read from disk for ever after.
///
/// Wizards' booster configuration for a set is fixed the day the set is printed
/// — the sheets and their weights do not move afterwards — so re-deriving them
/// from a multi-megabyte download on every launch was paying a large, repeated
/// cost for a value that never changes. `mtgjsonVersion` is what makes throwing
/// that assumption away cheap if it ever turns out to be wrong: a new MTGJSON
/// build invalidates the row and it is fetched again.
@Table("boosterOdds")
public struct BoosterOddsRecord: Equatable, Sendable {
  /// `"<setcode>/<kind>"`, lowercased.
  public var id: String
  public var setCode: String
  public var kind: String

  /// JSON-encoded `BoosterPackOdds`.
  public var payload: Data

  /// The MTGJSON build these were read out of.
  public var mtgjsonVersion: String?

  public var fetchedAt: Int64

  public init(
    id: String,
    setCode: String,
    kind: String,
    payload: Data,
    mtgjsonVersion: String?,
    fetchedAt: Int64
  ) {
    self.id = id
    self.setCode = setCode
    self.kind = kind
    self.payload = payload
    self.mtgjsonVersion = mtgjsonVersion
    self.fetchedAt = fetchedAt
  }
}

public extension BoosterOddsRecord {
  static func identifier(setCode: String, kind: BoosterPackKind) -> String {
    "\(setCode.lowercased())/\(kind.rawValue)"
  }

  init(
    setCode: String,
    kind: BoosterPackKind,
    odds: BoosterPackOdds,
    mtgjsonVersion: String?,
    fetchedAt: Date
  ) throws {
    self.init(
      id: Self.identifier(setCode: setCode, kind: kind),
      setCode: setCode.lowercased(),
      kind: kind.rawValue,
      payload: try JSONEncoder().encode(odds),
      mtgjsonVersion: mtgjsonVersion,
      fetchedAt: Int64(fetchedAt.timeIntervalSince1970)
    )
  }

  var odds: BoosterPackOdds? {
    try? JSONDecoder().decode(BoosterPackOdds.self, from: payload)
  }
}
