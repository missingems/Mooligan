import Foundation
import ScryfallKit

/// A set release worth drawing on the price chart.
///
/// MTGGoldfish marks releases on its price graphs because they are the single
/// biggest driver of a card's price inside a three month window — a reprint
/// tanks it, a format-warping new set lifts it. The chart plots one marker per
/// release day so the reader can tie a step in the line to a cause.
public struct SetReleaseMarker: Identifiable, Equatable, Sendable {
  public let id: String
  public let code: String
  public let name: String
  public let date: Date
  public let iconURL: URL?
}

extension SetReleaseMarker {
  /// Set types a player would recognise as "a new set came out".
  ///
  /// Promos, tokens, memorabilia, Alchemy and the digital-only rebalances all
  /// share release days with the products above and would stack three markers on
  /// one date without telling the reader anything.
  private static let chartableKinds: Set<MTGSet.Kind> = [
    .core, .expansion, .masters, .draftInnovation, .commander, .eternal,
  ]

  /// Scryfall's `released_at` is a plain `YYYY-MM-DD` in Pacific time with no
  /// zone marker. Parsed as UTC to match `PriceHistoryMapper.dayFormatter`, so a
  /// marker lands on the same x position as the price point for that day.
  private static let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  /// Releases inside `window`, one per day.
  ///
  /// Sets routinely ship alongside a Commander companion and a token sheet on the
  /// same date; the largest one is kept as that day's representative so the
  /// markers stay one-per-vertical-line.
  static func markers(from sets: [MTGSet], in window: DateInterval) -> [SetReleaseMarker] {
    var byDay: [Date: (marker: SetReleaseMarker, cardCount: Int)] = [:]

    for set in sets {
      guard
        set.digital == false,
        set.cardCount > 0,
        chartableKinds.contains(set.setType),
        let raw = set.releasedAt,
        let date = dayFormatter.date(from: raw),
        window.contains(date)
      else {
        continue
      }

      let marker = SetReleaseMarker(
        id: set.code,
        code: set.code,
        name: set.name,
        date: date,
        iconURL: URL(string: set.iconSvgUri)
      )

      if let existing = byDay[date], existing.cardCount >= set.cardCount { continue }
      byDay[date] = (marker, set.cardCount)
    }

    return byDay.values.map(\.marker).sorted { $0.date < $1.date }
  }
}

/// Process-wide cache of the release markers the price chart draws.
///
/// The markers are the same for every card — they are just "which sets came out
/// recently" — but the only way to get them is `getSets(.all)`, which reads
/// roughly a thousand sets out of SQLite and then folds, groups and sorts them
/// into display sections this chart never uses. Paying that once per card the
/// reader swiped to was a measurable part of the pager's stutter. Sets ship
/// weekly at most, so one fetch per launch is plenty.
actor SetReleaseMarkerStore {
  static let shared = SetReleaseMarkerStore()

  private var cached: [SetReleaseMarker]?
  private var inFlight: Task<[SetReleaseMarker], Never>?

  /// `loadSets` is injected rather than resolved here so the reducer keeps
  /// ownership of the dependency and tests can drive this without a live client.
  func markers(
    in window: DateInterval,
    loadSets: @Sendable @escaping () async -> [MTGSet]
  ) async -> [SetReleaseMarker] {
    if let cached { return cached.filter { window.contains($0.date) } }

    if let inFlight {
      return await inFlight.value.filter { window.contains($0.date) }
    }

    // Compute over the widest span any card can ask for, then let each caller
    // narrow it: one shared list serves every card's own date range.
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
  /// Tests need a clean slate; nothing in the app clears this.
  func reset() {
    cached = nil
    inFlight = nil
  }
#endif
}
