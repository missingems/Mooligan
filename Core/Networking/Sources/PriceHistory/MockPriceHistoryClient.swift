#if DEBUG
import Foundation
import ScryfallKit

/// Deterministic synthetic history for previews, the CardDetail runner, and the
/// `-uiTestMode` launch path, which swaps every network client for a mock.
public struct MockPriceHistoryClient: PriceHistoryClient {
  private let dayCount: Int

  public init(dayCount: Int = 90) {
    self.dayCount = dayCount
  }

  public func history(
    for card: Card,
    provider: PriceProvider,
    listType: PriceListType
  ) async throws -> PriceHistory {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt

    // Seed from the card id so a given card always draws the same curve.
    let seed = Double(abs(card.id.uuidString.hashValue % 1_000)) / 1_000
    let base = 4 + seed * 30

    func makeSeries(scale: Double) -> [PricePoint] {
      (0..<dayCount).compactMap { offset in
        guard
          let date = calendar.date(byAdding: .day, value: -(dayCount - 1 - offset), to: .now)
        else {
          return nil
        }
        let day = calendar.startOfDay(for: date)
        let drift = Double(offset) * 0.02 * (seed > 0.5 ? 1 : -0.4)
        let wobble = sin(Double(offset) / 7 + seed * 6) * base * 0.08
        let value = max(0.05, (base + drift + wobble) * scale)
        return PricePoint(date: day, amount: Decimal((value * 100).rounded() / 100))
      }
    }

    return PriceHistory(
      cardID: card.id.uuidString,
      provider: provider,
      listType: listType,
      series: [.normal: makeSeries(scale: 1), .foil: makeSeries(scale: 2.4)]
    )
  }
}
#endif
