import Foundation
import ScryfallKit

/// A set release the chart marks with a rule and the set's icon, when it falls within the plot.
public struct SetReleaseMarker: Identifiable, Equatable, Sendable {
  public let id: String
  public let code: String
  public let name: String
  public let date: Date
  public let iconURL: URL?
}

extension SetReleaseMarker {
  /// The kinds of set that move prices; promos, tokens and digital sets are noise on a chart.
  private static let chartableKinds: Set<MTGSet.Kind> = [
    .core, .expansion, .masters, .draftInnovation, .commander, .eternal,
  ]

  /// One marker per release day, keeping the largest set when several release together.
  static func markers(from sets: [MTGSet], in window: DateInterval) -> [SetReleaseMarker] {
    var byDay: [Date: (marker: SetReleaseMarker, cardCount: Int)] = [:]

    for set in sets {
      guard
        set.digital == false,
        set.cardCount > 0,
        chartableKinds.contains(set.setType),
        let date = UTCDay.date(from: set.releasedAt),
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
