@testable import CardDetail
import Foundation
import Networking
import ScryfallKit
import Testing

struct PriceHistoryDisplayTests {
  private let labels = PriceHistoryLabels()
  private let day: TimeInterval = 86_400
  private let end = Date(timeIntervalSince1970: 1_788_000_000)

  private func card(finishes: [Card.Finish], prices: Card.Prices = Card.Prices()) -> Card {
    var card = Card.mock()
    card.finishes = finishes
    card.prices = prices
    return card
  }

  private func dollars(_ value: String) -> String {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!.formatted(PriceChartStyle.price("USD"))
  }

  private func series(_ kind: PriceSeriesKind, _ amounts: [String]) -> PriceHistorySection.Series {
    let points = amounts.enumerated().map { offset, amount in
      PricePoint(
        date: end.addingTimeInterval(-Double(amounts.count - 1 - offset) * day),
        amount: Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX"))!
      )
    }
    return PriceHistorySection.Series(kind: kind, points: points)!
  }

  private func loaded(_ series: [PriceHistorySection.Series]) -> PriceHistoryState {
    .data(PriceHistorySection(series: series, currency: "USD"))
  }

  @Test func whileLoading_aFoilOnlyCardShouldShowJustFoilAtItsKnownPrice() {
    let display = PriceHistoryDisplay.loading(
      card: card(finishes: [.foil], prices: Card.Prices(usdFoil: "12.50")),
      labels: labels
    )

    #expect(display.status == .loading)
    #expect(display.summary.map(\.kind) == [.foil])
    #expect(display.summary.first?.priceText == dollars("12.50"))
    #expect(display.summary.first?.change == nil)
    #expect(display.statsColumns.map(\.kind) == [.foil])
    #expect(display.statsRows.map(\.values) == Array(repeating: [PriceChartStyle.missingValue], count: 4))
  }

  @Test func statsShouldOnlyListTheCardsFinishesEvenWhenOneHasNoData() {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil, .foil], prices: Card.Prices(usd: "1.00", usdFoil: "4.00")),
      state: loaded([series(.normal, ["1.00", "2.00"])]),
      labels: labels
    )

    #expect(display.statsColumns.map(\.kind) == [.normal, .foil])
    #expect(display.statsColumns.map(\.isAvailable) == [true, false])
    #expect(display.statsRows[0].values == [dollars("1.00"), PriceChartStyle.missingValue])
    #expect(display.summary.map(\.priceText) == [dollars("2.00"), dollars("4.00")])
    #expect(display.summary[0].change?.direction == .up)
    #expect(display.summary[1].change == nil)
  }

  @Test func regularAndEtchedCardsShouldNeverShowFoil() {
    let display = PriceHistoryDisplay.loading(card: card(finishes: [.nonfoil, .etched]), labels: labels)

    #expect(display.summary.map(\.kind) == [.normal, .etched])
    #expect(display.statsColumns.map(\.kind) == [.normal, .etched])
    #expect(display.summary.map(\.priceText) == [PriceChartStyle.missingValue, PriceChartStyle.missingValue])
  }

  @Test func everyStateShouldKeepTheSameRowsAndColumns() {
    let card = card(finishes: [.nonfoil, .foil], prices: Card.Prices(usd: "1.00"))
    let states: [PriceHistoryState] = [
      .loading,
      .unavailable,
      .failed,
      loaded([series(.normal, ["1.00", "2.00"]), series(.foil, ["3.00", "4.00"])]),
    ]
    let displays = states.map { PriceHistoryDisplay.make(card: card, state: $0, labels: labels) }

    #expect(Set(displays.map(\.summary.count)) == [2])
    #expect(Set(displays.map(\.statsColumns.count)) == [2])
    #expect(Set(displays.map(\.statsRows.count)) == [4])
  }

  @Test func whenTheCardHasNoFinishList_shouldFallBackToItsQuotedFinishes() {
    let display = PriceHistoryDisplay.loading(card: card(finishes: [], prices: Card.Prices(usdEtched: "9.00")), labels: labels)

    #expect(display.summary.map(\.kind) == [.etched])
  }

  @Test func scrubFramesShouldBePreformattedForEveryPoint() {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil]),
      state: loaded([series(.normal, ["1.00", "2.00", "10.00"])]),
      labels: labels
    )
    let frames = display.scrubFrames[.normal]

    #expect(frames?.prices == [dollars("1.00"), dollars("2.00"), dollars("10.00")])
    #expect(frames?.changes.first == .flat)
    #expect(frames?.changes[1].direction == .up)
    #expect(display.widestPriceText == dollars("10.00"))
    #expect(display.widestChange.text.count == frames?.changes.map(\.text.count).max())
  }

  @Test func theAxisShouldCarryItsFormattedLabels() {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil]),
      state: loaded([series(.normal, ["20.00", "40.00"])]),
      labels: labels
    )

    #expect(display.axis.tickLabels.count == display.axis.ticks.count)
    #expect(display.axis.label(at: 0) == display.axis.ticks[0].formatted(PriceChartStyle.axisPrice("USD", fractionDigits: display.axis.fractionDigits)))
    #expect(display.axis.label(at: 99) == "")
  }
}
