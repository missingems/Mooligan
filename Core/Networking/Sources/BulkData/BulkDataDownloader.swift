import ComposableArchitecture
import CryptoKit
import Foundation

public protocol BulkDataDownloading: Sendable {
  func stagedFile(for url: URL) async -> URL?
  func download(from url: URL) async throws -> URL
  func enqueueDownload(from url: URL) async
  func discardStagedFile(for url: URL) async
}

public enum BulkDataDownloadError: Error, Equatable {
  case badStatus(Int)
  case cancelled
  case transportFailed(String)
  case couldNotStage(String)
}

struct BulkDataStagingArea: Sendable {
  let directory: URL

  init() {
    let support = try? FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    )
    directory =
      (support ?? URL(fileURLWithPath: NSTemporaryDirectory()))
      .appendingPathComponent("BulkData", isDirectory: true)

    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  func url(for remote: URL) -> URL {
    let digest = SHA256.hash(data: Data(remote.absoluteString.utf8))
    let name = digest.compactMap { String(format: "%02x", $0) }.joined().prefix(32)
    return directory.appendingPathComponent("\(name).gz")
  }

  func existingFile(for remote: URL) -> URL? {
    let path = url(for: remote)
    return FileManager.default.fileExists(atPath: path.path) ? path : nil
  }

  func discard(for remote: URL) {
    try? FileManager.default.removeItem(at: url(for: remote))
  }

  func store(_ temporary: URL, for remote: URL) throws -> URL {
    let destination = url(for: remote)
    try? FileManager.default.removeItem(at: destination)
    try FileManager.default.moveItem(at: temporary, to: destination)
    return destination
  }
}

enum BulkDataTransferOutcome: Sendable {
  case staged(URL)
  case failed(BulkDataDownloadError)
}

struct BulkDataTransferEvent: Sendable {
  let remoteURL: URL
  let outcome: BulkDataTransferOutcome
}

final class BulkDataSessionDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
  let events: AsyncStream<BulkDataTransferEvent>

  private let continuation: AsyncStream<BulkDataTransferEvent>.Continuation
  private let staging: BulkDataStagingArea

  init(staging: BulkDataStagingArea) {
    self.staging = staging
    (events, continuation) = AsyncStream.makeStream()
    super.init()
  }

  func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    guard let remoteURL = downloadTask.originalRequest?.url else { return }

    if let status = (downloadTask.response as? HTTPURLResponse)?.statusCode,
      (200..<300).contains(status) == false
    {
      continuation.yield(
        BulkDataTransferEvent(remoteURL: remoteURL, outcome: .failed(.badStatus(status)))
      )
      return
    }

    do {
      let staged = try staging.store(location, for: remoteURL)
      continuation.yield(BulkDataTransferEvent(remoteURL: remoteURL, outcome: .staged(staged)))
    } catch {
      continuation.yield(
        BulkDataTransferEvent(
          remoteURL: remoteURL,
          outcome: .failed(.couldNotStage(error.localizedDescription))
        )
      )
    }
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didCompleteWithError error: (any Error)?
  ) {
    guard let remoteURL = task.originalRequest?.url, let error else { return }

    continuation.yield(
      BulkDataTransferEvent(
        remoteURL: remoteURL,
        outcome: .failed(.transportFailed(error.localizedDescription))
      )
    )
  }
}

public actor BackgroundBulkDataDownloader: BulkDataDownloading {
  public static let sessionIdentifier = "com.missingems.Mooligan.bulkData"

  private let staging: BulkDataStagingArea
  private let delegate: BulkDataSessionDelegate
  private let session: URLSession

  private var waiters: [URL: [CheckedContinuation<URL, any Error>]] = [:]
  private var eventPump: Task<Void, Never>?

  public init(isDiscretionary: Bool = true) {
    let staging = BulkDataStagingArea()
    let delegate = BulkDataSessionDelegate(staging: staging)

    let configuration = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
    configuration.isDiscretionary = isDiscretionary
    configuration.sessionSendsLaunchEvents = true
    configuration.waitsForConnectivity = true

    self.staging = staging
    self.delegate = delegate
    session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
  }

  public func stagedFile(for url: URL) -> URL? {
    staging.existingFile(for: url)
  }

  public func discardStagedFile(for url: URL) {
    staging.discard(for: url)
  }

  public func enqueueDownload(from url: URL) async {
    startEventPump()
    await startTaskIfNeeded(for: url)
  }

  public func download(from url: URL) async throws -> URL {
    if let staged = staging.existingFile(for: url) { return staged }

    startEventPump()
    await startTaskIfNeeded(for: url)

    return try await withCheckedThrowingContinuation { continuation in
      waiters[url, default: []].append(continuation)
    }
  }

  private func startEventPump() {
    guard eventPump == nil else { return }

    eventPump = Task { [delegate] in
      for await event in delegate.events {
        self.deliver(event)
      }
    }
  }

  private func deliver(_ event: BulkDataTransferEvent) {
    let waiting = waiters.removeValue(forKey: event.remoteURL) ?? []

    for continuation in waiting {
      switch event.outcome {
      case let .staged(file): continuation.resume(returning: file)
      case let .failed(error): continuation.resume(throwing: error)
      }
    }
  }
  
  private func startTaskIfNeeded(for url: URL) async {
    let alreadyRunning = await session.allTasks.contains { $0.originalRequest?.url == url }
    guard alreadyRunning == false else { return }

    session.downloadTask(with: url).resume()
  }
}

public enum BulkDataDownloaderKey: DependencyKey {
  public static let liveValue: any BulkDataDownloading = BackgroundBulkDataDownloader()
#if DEBUG
  public static let previewValue: any BulkDataDownloading = UnavailableBulkDataDownloader()
  public static let testValue: any BulkDataDownloading = UnavailableBulkDataDownloader()
#endif
}

public extension DependencyValues {
  var bulkDataDownloader: any BulkDataDownloading {
    get { self[BulkDataDownloaderKey.self] }
    set { self[BulkDataDownloaderKey.self] = newValue }
  }
}

#if DEBUG
public struct UnavailableBulkDataDownloader: BulkDataDownloading {
  public init() {}
  public func stagedFile(for url: URL) async -> URL? { nil }
  public func enqueueDownload(from url: URL) async {}
  public func discardStagedFile(for url: URL) async {}

  public func download(from url: URL) async throws -> URL {
    throw BulkDataDownloadError.cancelled
  }
}
#endif
