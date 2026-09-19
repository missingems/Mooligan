@testable import CardDetail
import Foundation
import Testing

struct PullOddsDenominatorTests {
  private let us = Locale(identifier: "en_US")

  @Test(arguments: [
    (1, "1"),
    (168, "168"),
    (2_100, "2,100"),
    (18_000, "18,000"),
    (99_999, "99,999"),
  ])
  func upToFiveDigits_shouldShowEveryFigureGroupedForTheRegion(packs: Int, expected: String) {
    #expect(packs.pullOddsDenominator(locale: us) == expected)
  }

  @Test func theGrouping_shouldBeTheRegionsOwn() {
    #expect(18_000.pullOddsDenominator(locale: Locale(identifier: "de_DE")) == "18.000")
  }

  @Test(arguments: [
    (100_000, "100 thousand"),
    (123_456, "123 thousand"),
    (250_499, "250 thousand"),
    (999_499, "999 thousand"),
  ])
  func sixFigures_shouldBeSaidInThousands(packs: Int, expected: String) {
    #expect(packs.pullOddsDenominator(locale: us) == expected)
  }

  @Test(arguments: [
    (999_500, "a million"),
    (1_000_000, "a million"),
    (1_049_999, "a million"),
    (1_050_000, "1.1 million"),
    (2_400_000, "2.4 million"),
    (12_600_000, "13 million"),
  ])
  func aMillionAndUp_shouldBeSaidInMillions(packs: Int, expected: String) {
    #expect(packs.pullOddsDenominator(locale: us) == expected)
  }
}
