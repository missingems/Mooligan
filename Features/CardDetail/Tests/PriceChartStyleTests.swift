@testable import CardDetail
import DesignComponents
import Foundation
import SwiftUI
import Networking
import Testing
import UIKit

struct PriceChartStyleTests {
  private func decimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
  }

  /// Small white text sits on the legality chips, so each chip colour keeps at least 4.3:1 against white.
  @Test func legalityChipsShouldKeepWhiteCaptionTextReadable() throws {
    let assets = [
      ("legal", DesignComponentsAsset.legal),
      ("banned", DesignComponentsAsset.banned),
      ("restricted", DesignComponentsAsset.restricted),
      ("notLegal", DesignComponentsAsset.notLegal),
    ]
    for (name, asset) in assets {
      let color = UIColor(asset.swiftUIColor).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
      var red: CGFloat = 0.0, green: CGFloat = 0.0, blue: CGFloat = 0.0, alpha: CGFloat = 0.0
      #expect(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))

      func linear(_ channel: CGFloat) -> CGFloat {
        channel <= 0.040_45 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
      }
      let luminance = 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
      let contrast = 1.05 / (luminance + 0.05)

      #expect(contrast >= 4.3, "\(name) has \(contrast):1 against white")
    }
  }

  @Test func priceAxisShouldStepInRoundNumbersWithAStepOfRoomBelowTheLow() {
    let axis = PriceChartStyle.priceAxis(for: 20.23...62.0)

    #expect(axis.ticks == [0.0, 20.0, 40.0, 60.0, 80.0])
    #expect(axis.domain == 0.0...80.0)
  }

  @Test func priceAxisShouldKeepAHighPricedCardAwayFromZero() {
    let axis = PriceChartStyle.priceAxis(for: 200.0...210.0)

    #expect(axis.ticks == [190.0, 200.0, 210.0, 220.0])
    #expect(axis.domain.lowerBound > 0.0)
  }

  @Test func priceAxisShouldLeaveAtLeastHalfAStepAboveAndBelowTheData() {
    for range in [20.23...41.3, 3.1...4.9, 0.12...0.45, 980.0...1_450.0] {
      let axis = PriceChartStyle.priceAxis(for: range)
      let step = axis.ticks[1] - axis.ticks[0]

      #expect(axis.domain.upperBound - range.upperBound >= step * 0.5 - 0.000_1)
      #expect(range.lowerBound - axis.domain.lowerBound >= min(step * 0.5, range.lowerBound) - 0.000_1)
      #expect(axis.ticks.first == axis.domain.lowerBound)
      #expect(axis.ticks.last == axis.domain.upperBound)
    }
  }

  @Test func axisLabelsShouldAlwaysShowTwoDecimals() {
    let twoDecimals = FloatingPointFormatStyle<Double>.Currency(code: "USD").presentation(.narrow).precision(.fractionLength(2))

    for range in [0.12...0.45, 20.23...41.3, 980.0...1_450.0] {
      let axis = PriceChartStyle.priceAxis(for: range).labeled(currencyCode: "USD")

      #expect(axis.tickLabels == axis.ticks.map { $0.formatted(twoDecimals) })
    }
    #expect(PriceChartStyle.priceAxis(for: 20.23...62.0).labeled(currencyCode: "USD").label(at: 1) == 20.0.formatted(twoDecimals))
  }

  /// Sub-dollar prices used to leave the top tick a hair above the domain (0.6000000000000001 against
  /// 0.6), and Swift Charts drew that grid line without its price.
  @Test func everyTickShouldSitInsideTheDomainWithTheEndsOnItsBounds() {
    var ranges: [ClosedRange<Double>] = []
    for index in 1...2_000 {
      let low = Double(index) * 0.037
      for factor in [1.05, 1.2, 1.5, 2.0, 3.0] {
        ranges.append(low...(low * factor))
      }
    }

    for range in ranges {
      let axis = PriceChartStyle.priceAxis(for: range)

      #expect(axis.ticks.first == axis.domain.lowerBound, "\(range): \(axis)")
      #expect(axis.ticks.last == axis.domain.upperBound, "\(range): \(axis)")
      #expect(axis.ticks.allSatisfy(axis.domain.contains), "\(range): \(axis)")
    }
  }

  @Test func ratioRangeShouldReadLowToHighAsWholePercents() {
    #expect(PriceChartStyle.ratioRangeText([0.64, 0.5]) == "\(PriceChartStyle.ratioText(0.5))–\(PriceChartStyle.ratioText(0.64))")
    #expect(PriceChartStyle.ratioText(0.5) == 0.5.formatted(.percent.precision(.fractionLength(0))))
  }

  @Test func ratiosThatReadTheSameShouldShowOneFigure() {
    #expect(PriceChartStyle.ratioRangeText([0.501, 0.499]) == PriceChartStyle.ratioText(0.5))
    #expect(PriceChartStyle.ratioRangeText([0.7]) == PriceChartStyle.ratioText(0.7))
    #expect(PriceChartStyle.ratioRangeText([]) == nil)
  }

  @Test func priceAxisShouldNeverGoNegativeOrCollapse() {
    #expect(PriceChartStyle.priceAxis(for: 0.1...40.0).domain.lowerBound == 0.0)
    #expect(PriceChartStyle.priceAxis(for: 5.0...5.0).domain.lowerBound < 5.0)
    #expect(PriceChartStyle.priceAxis(for: 5.0...5.0).domain.upperBound > 5.0)
    #expect(PriceChartStyle.priceAxis(for: 0.0...0.0) == PriceChartStyle.fallbackPriceAxis)
  }

  @Test func niceStepShouldRoundUpToOneTwoTwoAndAHalfOrFive() {
    #expect(PriceChartStyle.niceStep(14.0) == 20.0)
    #expect(PriceChartStyle.niceStep(2.2) == 2.5)
    #expect(abs(PriceChartStyle.niceStep(0.07) - 0.1) < 0.000_001)
    #expect(PriceChartStyle.niceStep(300.0) == 500.0)
  }
}
