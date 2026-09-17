import Foundation
import Networking
import ScryfallKit

struct PriceHistoryLoader: Sendable {
  static let attemptTimeout: Duration = .seconds(30)
  static let retryDelays: [Duration] = [.seconds(2), .seconds(4)]

  let client: any PriceHistoryClient
  let clock: any Clock<Duration>

  func load(card: Card, requests: [PriceSeriesRequest]) async -> PriceHistoryLoadOutcome {
    for attempt in 0...Self.retryDelays.count {
      if attempt > 0 {
        do {
          try await clock.sleep(for: Self.retryDelays[attempt - 1])
        } catch {
          return .failed
        }
      }

      switch await attemptLoad(card: card, requests: requests) {
      case let .loaded(histories): return .loaded(histories)
      case .noData: return .noData
      case .failed:
        guard Task.isCancelled == false else { return .failed }
        continue
      }
    }
    return .failed
  }

  private func attemptLoad(card: Card, requests: [PriceSeriesRequest]) async -> PriceHistoryLoadOutcome {
    await withTaskGroup(of: PriceHistoryLoadOutcome?.self) { group in
      group.addTask {
        do {
          return .loaded(try await client.histories(for: card, requests: requests))
        } catch let error as PriceHistoryClientError where error == .emptyResponse || error == .notConfigured {
          return .noData
        } catch is CancellationError {
          // The page left. Nothing to retry, and the caller checks its own cancellation.
          return nil
        } catch {
          return Task.isCancelled ? nil : .failed
        }
      }
      group.addTask {
        try? await clock.sleep(for: Self.attemptTimeout)
        return Task.isCancelled ? nil : .failed
      }

      let first = await group.next() ?? nil
      group.cancelAll()
      return first ?? .failed
    }
  }
}
