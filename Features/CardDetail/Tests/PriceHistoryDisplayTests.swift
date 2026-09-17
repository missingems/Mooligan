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

  private func decimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
  }

  private func dollars(_ value: String) -> String {
    decimal(value).formatted(PriceChartStyle.price("USD"))
  }

  private func series(_ kind: PriceSeriesKind, _ amounts: [String]) -> PriceHistorySection.Series {
    let points = amounts.enumerated().map { offset, amount in
      PricePoint(
        date: end.addingTimeInterval(-Double(amounts.count - 1 - offset) * day),
        amount: decimal(amount)
      )
    }
    return PriceHistorySection.Series(kind: kind, points: points)!
  }

  private func loaded(_ series: [PriceHistorySection.Series], buylistQuote: BuylistQuote? = nil) -> PriceHistoryState {
    .data(PriceHistorySection(series: series, currency: "USD", buylistQuote: buylistQuote))
  }

  @Test func whileLoading_aFoilOnlyCardShouldGreyOutRegularAndShowFoilAtItsKnownPrice() {
    let display = PriceHistoryDisplay.loading(
      card: card(finishes: [.foil], prices: Card.Prices(usdFoil: "12.50")),
      labels: labels
    )

    #expect(display.status == .loading)
    #expect(display.prices.map(\.kind) == [.normal, .foil])
    #expect(display.prices.map(\.priceText) == [PriceChartStyle.missingValue, dollars("12.50")])
    #expect(display.prices.map(\.isAvailable) == [false, true])
    #expect(display.buyBack.ratioText == PriceChartStyle.missingValue)
    #expect(display.buyBack.isAvailable == false)
  }

  @Test func thePricesShouldOnlyListTheCardsFinishesEvenWhenOneHasNoData() {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil, .foil], prices: Card.Prices(usd: "1.00")),
      state: loaded([series(.normal, ["1.00", "2.00"])]),
      labels: labels
    )

    #expect(display.prices.map(\.kind) == [.normal, .foil])
    #expect(display.prices.map(\.priceText) == [dollars("2.00"), PriceChartStyle.missingValue])
    #expect(display.prices.map(\.isAvailable) == [true, false])
    #expect(display.prices.map(\.label) == [PriceChartStyle.label(for: .normal), PriceChartStyle.label(for: .foil)])
  }

  @Test func whenAFinishHasNoChart_itsScryfallPriceShouldStandInForItsPrice() {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil, .foil], prices: Card.Prices(usd: "1.00", usdFoil: "4.00")),
      state: loaded([series(.normal, ["1.00", "2.00"])]),
      labels: labels
    )

    #expect(display.prices.map(\.priceText) == [dollars("2.00"), dollars("4.00")])
    #expect(display.buyBack.ratioText == PriceChartStyle.missingValue)
  }

  @Test func theBuyBackRatioShouldSpanTheLowestToHighestFinish() {
    let quote = BuylistQuote(
      provider: .cardkingdom,
      retail: [.normal: decimal("2.00"), .foil: decimal("10.00")],
      buylist: [.normal: decimal("1.00"), .foil: decimal("7.00")]
    )
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil, .foil]),
      state: loaded([series(.normal, ["1.00", "2.00"]), series(.foil, ["3.00", "4.00"])], buylistQuote: quote),
      labels: labels
    )

    #expect(display.buyBack.ratioText == PriceChartStyle.ratioRangeText([0.5, 0.7]))
    #expect(display.buyBack.provider == .cardkingdom)
    #expect(display.buyBack.finishes == [
      FinishBuyBack(kind: .normal, label: PriceChartStyle.label(for: .normal), priceText: dollars("1.00"), ratioText: PriceChartStyle.ratioText(0.5)),
      FinishBuyBack(kind: .foil, label: PriceChartStyle.label(for: .foil), priceText: dollars("7.00"), ratioText: PriceChartStyle.ratioText(0.7)),
    ])
  }

  @Test func aFinishBoughtWithoutARetailPriceShouldListItsPriceWithoutARatio() {
    let quote = BuylistQuote(
      provider: .cardkingdom,
      retail: [.normal: decimal("2.00")],
      buylist: [.normal: decimal("1.00"), .foil: decimal("7.00")]
    )
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil, .foil, .etched]),
      state: loaded([series(.normal, ["1.00", "2.00"])], buylistQuote: quote),
      labels: labels
    )

    #expect(display.buyBack.ratioText == PriceChartStyle.ratioText(0.5))
    #expect(display.buyBack.finishes.map(\.kind) == [.normal, .foil])
    #expect(display.buyBack.finishes.map(\.ratioText) == [PriceChartStyle.ratioText(0.5), nil])
  }

  /// The scrub readout only takes the finishes that have a price.
  @Test func pricedFinishesShouldLeaveOutTheDashes() {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil, .foil], prices: Card.Prices(usd: "1.00")),
      state: loaded([series(.normal, ["1.00", "2.00"])]),
      labels: labels
    )

    #expect(display.prices.map(\.isAvailable) == [true, false])
    #expect(display.pricedFinishes.map(\.kind) == [.normal])
  }

  @Test(arguments: [PriceHistoryState.unavailable, .failed])
  func withoutPriceHistory_shouldFallBackToScryfallAndDashTheRest(state: PriceHistoryState) {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil, .foil], prices: Card.Prices(usd: "1.50")),
      state: state,
      labels: labels
    )
    let unavailable = PriceChartStyle.missingValue

    #expect(display.prices.map(\.priceText) == [dollars("1.50"), unavailable])
    #expect(display.buyBack.ratioText == unavailable)
  }

  @Test func everyStateShouldKeepTheSameFinishes() {
    let card = card(finishes: [.nonfoil, .foil], prices: Card.Prices(usd: "1.00"))
    let states: [PriceHistoryState] = [
      .loading,
      .unavailable,
      .failed,
      loaded([series(.normal, ["1.00", "2.00"]), series(.foil, ["3.00", "4.00"])]),
    ]
    let displays = states.map { PriceHistoryDisplay.make(card: card, state: $0, labels: labels) }

    #expect(Set(displays.map(\.prices.count)) == [2])
  }

  @Test func aCardWithoutFinishesShouldStillShowRegularFoilAndBuyBack() {
    let display = PriceHistoryDisplay.loading(card: card(finishes: []), labels: labels)

    #expect(display.toolbarEntries == [.finish(.normal), .finish(.foil), .buyBack])
    #expect(display.prices.allSatisfy { $0.priceText == PriceChartStyle.missingValue && $0.isAvailable == false })
    #expect(display.toolbarEntries.toolbarRows().count == 1)
  }

  @Test func anEtchedCardWithoutFoilShouldShowEtchedInFoilsPlace() {
    let display = PriceHistoryDisplay.loading(card: card(finishes: [.nonfoil, .etched]), labels: labels)

    #expect(display.toolbarEntries == [.finish(.normal), .finish(.etched), .buyBack])
  }

  @Test func aCardWithFoilAndEtchedShouldShowFourItemsTwoToARow() {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil, .foil]),
      state: loaded([series(.normal, ["1.00", "2.00"]), series(.etched, ["5.00", "6.00"])]),
      labels: labels
    )

    #expect(display.toolbarEntries == [.finish(.normal), .finish(.foil), .finish(.etched), .buyBack])
    #expect(display.toolbarEntries.toolbarRows() == [[.finish(.normal), .finish(.foil)], [.finish(.etched), .buyBack]])
  }

  @Test func thePricesShouldOpenTheCardsTCGplayerPage() {
    var subject = card(finishes: [.nonfoil, .foil])
    subject.purchaseUris = ["tcgplayer": "https://partner.tcgplayer.com/c/1/2?u=https%3A%2F%2Fwww.tcgplayer.com%2Fproduct%2F1"]

    let display = PriceHistoryDisplay.loading(card: subject, labels: labels)

    #expect(display.tcgplayerURL == URL(string: "https://partner.tcgplayer.com/c/1/2?u=https%3A%2F%2Fwww.tcgplayer.com%2Fproduct%2F1"))
  }

  @Test(arguments: [nil, ["cardmarket": "https://www.cardmarket.com/x"], ["tcgplayer": "http://www.tcgplayer.com/x"], ["tcgplayer": "  "]])
  func withoutASecureTCGplayerLink_thePricesShouldOpenNothing(uris: [String: String]?) {
    var subject = card(finishes: [.nonfoil])
    subject.purchaseUris = uris

    #expect(PriceHistoryDisplay.tcgplayerURL(of: subject) == nil)
  }

  @Test func scrubPricesShouldBePreformattedForEveryPoint() {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil]),
      state: loaded([series(.normal, ["1.00", "2.00", "10.00"])]),
      labels: labels
    )

    #expect(display.scrubPrices[.normal] == [dollars("1.00"), dollars("2.00"), dollars("10.00")])
  }

  @Test func whileScrubbing_eachPriceShouldReadTheScrubbedDay() throws {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil, .foil], prices: Card.Prices(usdFoil: "9.00")),
      state: loaded([series(.normal, ["1.00", "2.00", "10.00"])]),
      labels: labels
    )
    let regular = try #require(display.prices.first { $0.kind == .normal })
    let foil = try #require(display.prices.first { $0.kind == .foil })
    let interaction = ChartInteraction()

    #expect(display.priceText(for: regular, interaction: interaction) == dollars("10.00"))

    interaction.scrubbedDate = end.addingTimeInterval(-day)
    #expect(display.priceText(for: regular, interaction: interaction) == dollars("2.00"))
    #expect(display.priceText(for: foil, interaction: interaction) == dollars("9.00"))

    interaction.endScrub()
    #expect(display.priceText(for: regular, interaction: interaction) == regular.priceText)
  }

  @Test func whileLoading_theChartShouldSpanTheLastThreeMonthsAroundTheScryfallPrice() {
    let display = PriceHistoryDisplay.loading(
      card: card(finishes: [.nonfoil, .foil], prices: Card.Prices(usd: "31.80", usdFoil: "240.90")),
      labels: labels
    )

    #expect(display.chart.spanInDays == ChartDerivedData.windowInDays)
    #expect(display.chart.dateRange.upperBound == PriceHistorySection.today)
    #expect(display.axis.domain.contains(31.80 * (1.0 - PriceChartStyle.estimatedAxisPadding)))
    #expect(display.axis.domain.contains(240.90 * (1.0 + PriceChartStyle.estimatedAxisPadding)))
    #expect(display.axis.domain != PriceChartStyle.fallbackPriceAxis.domain)
    #expect(display.axis.tickLabels.count == display.axis.ticks.count)
  }

  @Test func withoutAnyKnownPrice_theEstimatedAxisShouldFallBack() {
    let display = PriceHistoryDisplay.loading(card: card(finishes: [.nonfoil]), labels: labels)

    #expect(display.axis.domain == PriceChartStyle.fallbackPriceAxis.domain)
  }

  @Test func theAxisShouldCarryItsFormattedLabels() {
    let display = PriceHistoryDisplay.make(
      card: card(finishes: [.nonfoil]),
      state: loaded([series(.normal, ["20.00", "40.00"])]),
      labels: labels
    )

    #expect(display.axis.tickLabels.count == display.axis.ticks.count)
    #expect(display.axis.label(at: 0) == display.axis.ticks[0].formatted(PriceChartStyle.axisPrice("USD")))
    #expect(display.axis.label(at: 99) == "")
  }

  @Test func theBuyBackShouldLinkToTheVendorsBuylistSearchForTheCardsFrontFace() throws {
    var subject = card(finishes: [.nonfoil])
    subject.name = "Fable of the Mirror-Breaker // Reflection of Kiki-Jiki"

    let display = PriceHistoryDisplay.loading(card: subject, labels: labels)
    let url = try #require(display.buyBack.sellURL)
    let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)

    #expect(display.buyBack.provider == .cardkingdom)
    #expect(url.host() == "www.cardkingdom.com")
    #expect(query.first { $0.name == "filter[name]" }?.value == "Fable of the Mirror-Breaker")
  }
}
