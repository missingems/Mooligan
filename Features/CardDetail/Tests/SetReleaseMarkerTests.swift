@testable import CardDetail
import Foundation
import ScryfallKit
import Testing

/// Covers which set releases earn a marker on the price chart and how same-day
/// releases collapse.
struct SetReleaseMarkerTests {
  private let windowStart = Date(timeIntervalSince1970: 1_780_000_000)
  private var window: DateInterval {
    DateInterval(start: windowStart, end: windowStart.addingTimeInterval(90 * 86_400))
  }

  /// The day 10 days into the window, formatted the way Scryfall reports it.
  private var insideDay: String { day(offset: 10) }

  private func day(offset: Int) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: windowStart.addingTimeInterval(Double(offset) * 86_400))
  }

  private func set(
    code: String,
    type: MTGSet.Kind = .expansion,
    releasedAt: String?,
    cardCount: Int = 250,
    digital: Bool = false
  ) -> MTGSet {
    MTGSet(
      id: UUID(), code: code, mtgoCode: nil, tcgplayerId: 0,
      name: "Set \(code)", setType: type, releasedAt: releasedAt,
      blockCode: nil, block: nil, parentSetCode: nil,
      cardCount: cardCount, printedSize: cardCount, digital: digital,
      foilOnly: false, nonfoilOnly: false,
      scryfallUri: "https://scryfall.com/sets/\(code)",
      uri: "https://api.scryfall.com/sets/\(code)",
      iconSvgUri: "https://svgs.scryfall.io/sets/\(code).svg",
      searchUri: "https://api.scryfall.com/cards/search?q=e%3A\(code)"
    )
  }

  @Test func whenSetReleasedInsideWindow_shouldProduceAMarker() {
    let markers = SetReleaseMarker.markers(
      from: [set(code: "abc", releasedAt: insideDay)],
      in: window
    )

    #expect(markers.count == 1)
    #expect(markers.first?.code == "abc")
    #expect(markers.first?.iconURL == URL(string: "https://svgs.scryfall.io/sets/abc.svg"))
  }

  @Test func whenSetReleasedOutsideWindow_shouldBeDropped() {
    let markers = SetReleaseMarker.markers(
      from: [set(code: "old", releasedAt: day(offset: -30))],
      in: window
    )

    #expect(markers.isEmpty)
  }

  /// Promos, tokens and Alchemy rebalances share release days with real sets and
  /// would stack markers without telling the reader anything.
  @Test func whenSetIsNotAPlayerFacingRelease_shouldBeDropped() {
    let noise: [MTGSet.Kind] = [.token, .promo, .memorabilia, .alchemy, .funny, .minigame]

    for kind in noise {
      let markers = SetReleaseMarker.markers(
        from: [set(code: "n", type: kind, releasedAt: insideDay)],
        in: window
      )
      #expect(markers.isEmpty, "\(kind.rawValue) should not be marked")
    }
  }

  @Test func whenSetIsDigitalOrEmpty_shouldBeDropped() {
    let markers = SetReleaseMarker.markers(
      from: [
        set(code: "dig", releasedAt: insideDay, digital: true),
        set(code: "empty", releasedAt: insideDay, cardCount: 0),
        set(code: "undated", releasedAt: nil),
      ],
      in: window
    )

    #expect(markers.isEmpty)
  }

  /// A main set, its Commander companion and its token sheet all land on one day;
  /// only the largest should hold that vertical line.
  @Test func whenSeveralSetsShareADay_shouldKeepOnlyTheLargest() {
    let markers = SetReleaseMarker.markers(
      from: [
        set(code: "cmd", type: .commander, releasedAt: insideDay, cardCount: 80),
        set(code: "main", type: .expansion, releasedAt: insideDay, cardCount: 320),
      ],
      in: window
    )

    #expect(markers.count == 1)
    #expect(markers.first?.code == "main")
  }

  @Test func whenSeveralReleases_shouldSortAscendingByDate() {
    let markers = SetReleaseMarker.markers(
      from: [
        set(code: "late", releasedAt: day(offset: 60)),
        set(code: "early", releasedAt: day(offset: 5)),
        set(code: "mid", releasedAt: day(offset: 30)),
      ],
      in: window
    )

    #expect(markers.map(\.code) == ["early", "mid", "late"])
  }
}
