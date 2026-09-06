import ComposableArchitecture
import Foundation
import OSLog
import ScryfallKit

let bulkSyncLogger = Logger(subsystem: "com.missingems.Mooligan", category: "BulkDataSync")

public enum BulkSyncOutcome: Equatable, Sendable {
  case skippedNotDue
  case upToDate
  case downloadQueued
  case ingested(cards: Int)
  case failed(String)
}

public enum BulkSyncPhase: Equatable, Sendable {
  case idle
  case checking
  case downloading
  case ingesting(cards: Int)
  case complete(cards: Int)
  case failed(String)
}

public protocol BulkDataSyncManaging: Sendable {
  @discardableResult
  func sync(force: Bool) async -> BulkSyncOutcome
  func phase() async -> BulkSyncPhase
  func phases() async -> AsyncStream<BulkSyncPhase>
}

public extension BulkDataSyncManaging {
  @discardableResult
  func sync() async -> BulkSyncOutcome {
    await sync(force: false)
  }
}

public actor BulkDataSyncManager: BulkDataSyncManaging {
  static let batchSize = 2_000

  @Dependency(\.bulkDataRequestClient) private var client
  @Dependency(\.bulkDataDownloader) private var downloader
  @Dependency(\.date.now) private var now

  private let store = CardStore()
  private let bulkType: String

  private var currentPhase: BulkSyncPhase = .idle
  private var observers: [UUID: AsyncStream<BulkSyncPhase>.Continuation] = [:]
  private var isRunning = false

  public init(bulkType: String = BulkDataItem.defaultCardsType) {
    self.bulkType = bulkType
  }

  public func phase() -> BulkSyncPhase {
    currentPhase
  }

  public func phases() -> AsyncStream<BulkSyncPhase> {
    let id = UUID()
    let (stream, continuation) = AsyncStream<BulkSyncPhase>.makeStream()

    continuation.yield(currentPhase)
    observers[id] = continuation
    continuation.onTermination = { [weak self] _ in
      Task { await self?.removeObserver(id) }
    }

    return stream
  }

  private func removeObserver(_ id: UUID) {
    observers[id] = nil
  }

  private func publish(_ phase: BulkSyncPhase) {
    currentPhase = phase
    for observer in observers.values {
      observer.yield(phase)
    }
  }

  @discardableResult
  public func sync(force: Bool = false) async -> BulkSyncOutcome {
    guard isRunning == false else { return .skippedNotDue }
    isRunning = true
    defer { isRunning = false }

    do {
      return try await run(force: force)
    } catch is CancellationError {
      publish(.idle)
      return .failed("cancelled")
    } catch {
      bulkSyncLogger.error("sync failed: \(error.localizedDescription)")
      publish(.failed(error.localizedDescription))
      await updateState { $0.status = SyncStateRecord.Status.failed.rawValue }
      return .failed(error.localizedDescription)
    }
  }

  private func run(force: Bool) async throws -> BulkSyncOutcome {
    let state = try await store.syncState(id: bulkType)

    if force == false,
      BulkRefreshSchedule.isCheckDue(lastCheckedAt: state?.lastCheckedDate, now: now) == false
    {
      return .skippedNotDue
    }

    publish(.checking)

    let item = try await client.bulkDataItems().item(ofType: bulkType)
    let checkedAt = Int64(now.timeIntervalSince1970)

    await updateState { $0.lastCheckedAt = checkedAt }

    guard shouldIngest(item: item, state: state, force: force) else {
      publish(.complete(cards: state?.ingestedCardCount ?? 0))
      return .upToDate
    }

    guard let downloadURL = URL(string: item.jsonlDownloadURI) else {
      throw BulkDataRequestClientError.invalidURL
    }

    guard let file = await downloader.stagedFile(for: downloadURL) else {
      publish(.downloading)
      await updateState { $0.status = SyncStateRecord.Status.downloading.rawValue }
      await downloader.enqueueDownload(from: downloadURL)
      return .downloadQueued
    }

    let count = try await ingest(file: file, item: item)
    await downloader.discardStagedFile(for: downloadURL)
    return .ingested(cards: count)
  }

  private func shouldIngest(
    item: BulkDataItem,
    state: SyncStateRecord?,
    force: Bool
  ) -> Bool {
    guard let state, state.hasCompleteCatalog else { return true }
    if force { return true }
    guard state.remoteUpdatedAt != item.updatedAt else { return false }

    return BulkRefreshSchedule.isFullRefreshDue(lastIngestedAt: state.lastIngestedDate, now: now)
  }

  private enum LineOutcome {
    case card(Card)
    case notPaper
    case malformed
  }

  private static func classify(_ line: Data) -> LineOutcome {
    guard let card = try? CardPayloadCodec.decodeScryfall(line) else { return .malformed }

    return card.games.contains(.paper) ? .card(card) : .notPaper
  }

  private func ingest(file: URL, item: BulkDataItem) async throws -> Int {
    publish(.ingesting(cards: 0))
    await updateState { $0.status = SyncStateRecord.Status.ingesting.rawValue }

    let startedAt = now

    let handle = try FileHandle(forReadingFrom: file)
    defer { try? handle.close() }

    let stream = try GzipInflateStream()
    var splitter = JSONLineSplitter()
    var batch: [Card] = []
    batch.reserveCapacity(Self.batchSize)

    var ingested = 0
    var skipped = 0
    var malformed = 0

    while let chunk = try handle.read(upToCount: 256 * 1024), chunk.isEmpty == false {
      try Task.checkCancellation()

      for line in splitter.lines(from: try stream.inflate(chunk)) {
        switch Self.classify(line) {
        case let .card(card): batch.append(card)
        case .notPaper: skipped += 1
        case .malformed: malformed += 1
        }
      }

      if batch.count >= Self.batchSize {
        ingested += try await store.upsert(cards: batch, source: .bulk)
        batch.removeAll(keepingCapacity: true)
        publish(.ingesting(cards: ingested))
      }

      if stream.isComplete { break }
    }

    if let last = splitter.flush() {
      switch Self.classify(last) {
      case let .card(card): batch.append(card)
      case .notPaper: skipped += 1
      case .malformed: malformed += 1
      }
    }

    if batch.isEmpty == false {
      ingested += try await store.upsert(cards: batch, source: .bulk)
    }

    try stream.finish()

    let withdrawn = try await store.deleteBulkCards(ingestedBefore: startedAt)

    bulkSyncLogger.info(
      """
      ingested \(ingested) cards, skipped \(skipped) non-paper, \(malformed) malformed, \
      removed \(withdrawn) withdrawn
      """
    )

    let ingestedAt = Int64(now.timeIntervalSince1970)
    await updateState {
      $0.status = SyncStateRecord.Status.complete.rawValue
      $0.ingestedCardCount = ingested
      $0.lastIngestedAt = ingestedAt
      $0.remoteUpdatedAt = item.updatedAt
    }

    publish(.complete(cards: ingested))
    return ingested
  }

  private func updateState(_ mutate: (inout SyncStateRecord) -> Void) async {
    do {
      var record = try await store.syncState(id: bulkType) ?? SyncStateRecord(id: bulkType)
      mutate(&record)
      try await store.upsert(syncState: record)
    } catch {
      bulkSyncLogger.error("could not persist sync state: \(error.localizedDescription)")
    }
  }
}

public enum BulkDataSyncManagerKey: DependencyKey {
  public static var liveValue: any BulkDataSyncManaging { BulkDataSyncManager() }

#if DEBUG
  public static let previewValue: any BulkDataSyncManaging = InertBulkDataSyncManager()
  public static let testValue: any BulkDataSyncManaging = InertBulkDataSyncManager()
#endif
}

public extension DependencyValues {
  var bulkDataSyncManager: any BulkDataSyncManaging {
    get { self[BulkDataSyncManagerKey.self] }
    set { self[BulkDataSyncManagerKey.self] = newValue }
  }
}

#if DEBUG
public struct InertBulkDataSyncManager: BulkDataSyncManaging {
  public init() {}
  public func sync(force: Bool) async -> BulkSyncOutcome { .skippedNotDue }
  public func phase() async -> BulkSyncPhase { .idle }
  public func phases() async -> AsyncStream<BulkSyncPhase> {
    AsyncStream { $0.finish() }
  }
}
#endif
