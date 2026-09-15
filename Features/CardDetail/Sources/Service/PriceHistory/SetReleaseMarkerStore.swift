import Foundation
import ScryfallKit

actor SetReleaseMarkerStore {
  static let shared = SetReleaseMarkerStore()

  private var cached: [SetReleaseMarker]?
  private var inFlight: Task<[SetReleaseMarker], Never>?

  func markers(
    in window: DateInterval,
    loadSets: @Sendable @escaping () async -> [MTGSet]
  ) async -> [SetReleaseMarker] {
    if let cached { return cached.filter { window.contains($0.date) } }

    if let inFlight {
      return await inFlight.value.filter { window.contains($0.date) }
    }

    let widest = DateInterval(
      start: Date().addingTimeInterval(-400 * 86_400),
      end: Date().addingTimeInterval(86_400)
    )
    let task = Task { SetReleaseMarker.markers(from: await loadSets(), in: widest) }
    inFlight = task
    let value = await task.value
    cached = value
    inFlight = nil
    return value.filter { window.contains($0.date) }
  }

#if DEBUG
  func reset() {
    cached = nil
    inFlight = nil
  }
#endif
}
