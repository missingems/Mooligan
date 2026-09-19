import Foundation

extension Int {
  /// A count of packs the way it would be said: "168", "18,000" grouped as the region groups it,
  /// "250 thousand", "a million", "2.4 million". Past five digits every figure is noise; nobody
  /// reads 1,234,567 packs as anything but about a million.
  func pullOddsDenominator(locale: Locale = .current) -> String {
    if self < 100_000 {
      return formatted(.number.locale(locale))
    }

    // Anything that would round up to a thousand thousand is a million.
    if self < 999_500 {
      let thousands = (Double(self) / 1_000).rounded()
      return String(localized: "\(thousands.formatted(.number.locale(locale))) thousand")
    }

    let millions = Double(self) / 1_000_000
    let rounded = millions < 10 ? (millions * 10).rounded() / 10 : millions.rounded()
    return rounded == 1
      ? String(localized: "a million")
      : String(localized: "\(rounded.formatted(.number.locale(locale))) million")
  }
}
