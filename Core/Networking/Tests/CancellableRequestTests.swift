import Apollo
import Foundation
@testable import Networking
import Testing

struct CancellableRequestTests {
  private final class FakeRequest: Apollo.Cancellable, @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    private var started = false

    var isCancelled: Bool { lock.withLock { cancelled } }
    var isStarted: Bool { lock.withLock { started } }

    func markStarted() { lock.withLock { started = true } }
    func cancel() { lock.withLock { cancelled = true } }
  }

  private typealias Payload = MTGGraphQLAPI.CardPurchaseUrlsQuery.Data

  @Test func whenTheTaskIsCancelled_shouldCancelTheRequestAndStopWaiting() async throws {
    let request = CancellableRequest<Payload>()
    let fake = FakeRequest()

    let task = Task<Void, any Error> {
      try await withTaskCancellationHandler {
        _ = try await withCheckedThrowingContinuation { continuation in
          request.begin(continuation) {
            fake.markStarted()
            return fake
          }
        }
      } onCancel: {
        request.cancel()
      }
    }

    while fake.isStarted == false { await Task.yield() }
    task.cancel()

    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(fake.isCancelled)
  }

  @Test func whenCancelledBeforeStarting_shouldNeverSendTheRequest() async throws {
    let request = CancellableRequest<Payload>()
    let fake = FakeRequest()
    request.cancel()

    await #expect(throws: CancellationError.self) {
      _ = try await withCheckedThrowingContinuation { continuation in
        request.begin(continuation) {
          fake.markStarted()
          return fake
        }
      }
    }
    #expect(fake.isStarted == false)
  }
}
