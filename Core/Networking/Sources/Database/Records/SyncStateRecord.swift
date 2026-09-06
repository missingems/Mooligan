import Foundation
import SQLiteData

@Table("syncState")
public struct SyncStateRecord: Equatable, Sendable {
  public enum Status: String, Sendable {
    case never
    case downloading
    case ingesting
    case complete
    case failed
  }

  public var id: String
  public var remoteUpdatedAt: String?
  public var etag: String?
  public var lastCheckedAt: Int64?
  public var lastIngestedAt: Int64?
  public var ingestedCardCount: Int
  public var status: String

  public init(
    id: String,
    remoteUpdatedAt: String? = nil,
    etag: String? = nil,
    lastCheckedAt: Int64? = nil,
    lastIngestedAt: Int64? = nil,
    ingestedCardCount: Int = 0,
    status: String = Status.never.rawValue
  ) {
    self.id = id
    self.remoteUpdatedAt = remoteUpdatedAt
    self.etag = etag
    self.lastCheckedAt = lastCheckedAt
    self.lastIngestedAt = lastIngestedAt
    self.ingestedCardCount = ingestedCardCount
    self.status = status
  }
}

public extension SyncStateRecord {
  var lastCheckedDate: Date? {
    lastCheckedAt.map { Date(timeIntervalSince1970: Double($0)) }
  }

  var lastIngestedDate: Date? {
    lastIngestedAt.map { Date(timeIntervalSince1970: Double($0)) }
  }

  var syncStatus: Status {
    Status(rawValue: status) ?? .never
  }

  var hasCompleteCatalog: Bool {
    syncStatus == .complete && ingestedCardCount > 0
  }
}
