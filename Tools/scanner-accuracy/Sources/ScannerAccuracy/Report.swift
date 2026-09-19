import Foundation

/// Rates by niche and environment, as tables for the terminal.
struct Report {
  let outcomes: [ScanOutcome]
  let faces: [String: ScannableFace]

  func print() {
    let niches = outcomes.map(\.niche).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
    let environments = SimulatedEnvironment.allCases.filter { environment in outcomes.contains { $0.environment == environment } }

    table("Card found and cropped (corners within 3% of its height)", niches: niches, environments: environments) {
      $0.isDetected
    }
    table("Recognised as the right card (any printing)", niches: niches, environments: environments) {
      quality($0) >= .sameCard
    }

    let total = Double(outcomes.count)
    let qualities = outcomes.map(quality)
    Swift.print("\nOf \(outcomes.count) frames:")
    for (label, minimum) in [("exact printing", MatchQuality.exactPrinting), ("same art", .sameArt), ("right card", .sameCard)] {
      let rate = Double(qualities.filter { $0 >= minimum }.count) / total
      Swift.print("  \(label.padding(toLength: 16, withPad: " ", startingAt: 0)) \(percent(rate))")
    }
    Swift.print("  wrong card       \(percent(Double(qualities.filter { $0 == .wrongCard }.count) / total))")
    Swift.print("  no match         \(percent(Double(qualities.filter { $0 == .none }.count) / total))")
  }

  func quality(_ outcome: ScanOutcome) -> MatchQuality {
    MatchQuality(match: outcome.match, expected: outcome.expected, faces: faces)
  }

  private func table(
    _ title: String,
    niches: [String],
    environments: [SimulatedEnvironment],
    passes: (ScanOutcome) -> Bool
  ) {
    func rate(_ selected: [ScanOutcome]) -> String {
      selected.isEmpty ? "-" : percent(Double(selected.filter(passes).count) / Double(selected.count))
    }
    func cell(_ text: String, _ width: Int) -> String {
      String(repeating: " ", count: max(0, width - text.count)) + text
    }

    Swift.print("\n\(title)")
    Swift.print("".padding(toLength: 13, withPad: " ", startingAt: 0)
      + environments.map { cell($0.rawValue, 8) }.joined() + cell("all", 8))
    for niche in niches {
      let row = outcomes.filter { $0.niche == niche }
      Swift.print(niche.padding(toLength: 13, withPad: " ", startingAt: 0)
        + environments.map { environment in cell(rate(row.filter { $0.environment == environment }), 8) }.joined()
        + cell(rate(row), 8))
    }
    Swift.print("all".padding(toLength: 13, withPad: " ", startingAt: 0)
      + environments.map { environment in cell(rate(outcomes.filter { $0.environment == environment }), 8) }.joined()
      + cell(rate(outcomes), 8))
  }

  private func percent(_ rate: Double) -> String {
    "\(Int((rate * 100).rounded()))%"
  }
}
