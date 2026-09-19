import Foundation
import Networking
import ScryfallKit

extension InformationWidget {
  var insightTitle: String {
    switch self {
    case .set: String(localized: "Set & Rarity")
    case .pullOdds: String(localized: "Pull Rate")
    case .collectorNumber: String(localized: "Collector Number")
    case .colorIdentity: String(localized: "Color Identity")
    case .manaValue: String(localized: "Mana Value")
    case .loyalty: String(localized: "Loyalty")
    case .powerToughness: String(localized: "Power & Toughness")
    }
  }

  /// What the tile means on any card. Written by hand, so it is right whether or not the on-device
  /// model can add to it, and handed to the model as the definition to work from.
  var insightSummary: String {
    switch self {
    case .set:
      String(localized: "The set symbol shows which release printed this card, and its color shows the rarity: black for common, silver for uncommon, gold for rare and orange-red for mythic rare. The rarer the card, the fewer of it go into each pack.")
    case .pullOdds:
      String(localized: "How many packs you would open, on average, to find this exact printing. The odds come from the booster configuration Wizards of the Coast prints from, as collected by MTGJSON, and count every slot the card can land in, foil or not. Each pack is a fresh chance, so opening that many does not promise one.")
    case .collectorNumber:
      String(localized: "The collector number identifies this printing within its set. Versions of the same card with a different frame, border or art get numbers of their own, usually after the main set, which is how collectors tell them apart.")
    case .colorIdentity:
      String(localized: "A card's color identity is every color among the mana symbols in its cost and rules text, along with any color indicator. In Commander, every card in a deck must fit within its commander's color identity.")
    case .manaValue:
      String(localized: "Mana value is the total amount of mana in a card's mana cost, whatever its colors. An X in the cost counts as zero, except while the spell is on the stack.")
    case .loyalty:
      String(localized: "A planeswalker enters with this many loyalty counters. Its abilities add or remove them, damage dealt to it removes them, and when none are left it is put into its owner's graveyard.")
    case .powerToughness:
      String(localized: "Power is how much damage a creature deals in combat. Toughness is how much damage it can take in one turn before it is destroyed.")
    }
  }

  func insightFactGroups(card: Card, faceDirection: MagicCardFaceDirection?) -> [InsightFactGroup] {
    switch self {
    case let .set(code, rarity, _):
      [InsightFactGroup(facts: [
        InsightFact(title: String(localized: "Set"), value: card.setName),
        InsightFact(title: String(localized: "Code"), value: code.uppercased()),
        InsightFact(title: String(localized: "Released"), value: releaseDate(of: card)),
        InsightFact(title: String(localized: "Rarity"), value: rarity.rawValue.capitalized),
      ])]

    case let .pullOdds(odds, _, _):
      [estimateGroup(odds)] + odds.products.map { productGroup($0, card: card) }

    case let .collectorNumber(number):
      [InsightFactGroup(facts: [
        InsightFact(title: String(localized: "Number"), value: "#\(number.uppercased())"),
        InsightFact(title: String(localized: "Set"), value: card.setName),
        InsightFact(
          title: String(localized: "Printing"),
          value: card.treatments.isEmpty ? String(localized: "Regular") : card.treatments.formatted()
        ),
      ])]

    case .colorIdentity:
      [InsightFactGroup(facts: [
        InsightFact(
          title: String(localized: "Identity"),
          value: card.colorIdentity.isEmpty
            ? String(localized: "Colorless")
            : card.colorIdentity.map(\.name).formatted()
        ),
        InsightFact(title: String(localized: "Mana cost"), symbols: card.manaCost(faceDirection: faceDirection)),
      ]
      .filter { $0.value != nil || $0.symbols.isEmpty == false })]

    case let .manaValue(value):
      [InsightFactGroup(facts: [
        InsightFact(title: String(localized: "Mana value"), value: manaValue(value)),
        InsightFact(title: String(localized: "Mana cost"), symbols: card.manaCost(faceDirection: faceDirection)),
      ]
      .filter { $0.value != nil || $0.symbols.isEmpty == false })]

    case .loyalty, .powerToughness:
      []
    }
  }

  /// The one figure the tile shows: any pack of the set, whichever product it is, with the guess it
  /// rests on spelled out under it.
  private func estimateGroup(_ odds: CardPullOdds) -> InsightFactGroup {
    let setName = odds.headline.setName
    return InsightFactGroup(
      header: String(localized: "Estimate"),
      facts: [
        InsightFact(
          title: String(localized: "Any \(setName) pack"),
          value: odds.estimatePacks.map(Self.packs)
        ),
      ],
      footer: mixNote(odds.mix, setName: setName)
    )
  }

  /// One product's exact odds: in any finish, and in each finish it comes in, a row each.
  private func productGroup(_ product: ProductPullOdds, card: Card) -> InsightFactGroup {
    var facts: [InsightFact] = []
    switch (product.foilPacks, product.nonFoilPacks) {
    case let (foil?, nonFoil?):
      facts = [
        InsightFact(title: String(localized: "Any finish"), value: product.packs.map(Self.packs)),
        InsightFact(title: String(localized: "Foil"), value: Self.packs(foil)),
        InsightFact(title: String(localized: "Non-foil"), value: Self.packs(nonFoil)),
      ]
    case let (foil?, nil):
      facts = [InsightFact(title: String(localized: "Foil only"), value: Self.packs(foil))]
    case let (nil, nonFoil?):
      facts = [InsightFact(title: String(localized: "Non-foil only"), value: Self.packs(nonFoil))]
    case (nil, nil):
      facts = [InsightFact(title: String(localized: "Any finish"), value: product.packs.map(Self.packs))]
    }
    // A commander card's odds are its parent set's product, which is worth naming in full.
    return InsightFactGroup(
      header: product.setName == card.setName ? product.name : "\(product.setName) \(product.name)",
      facts: facts
    )
  }

  /// "A guess across Bloomburrow's packs, taking the packs opened to be about 80% Play Boosters, 10%
  /// Collector Boosters and 10% other packs."
  private func mixNote(_ mix: [PackShare], setName: String) -> String {
    let parts = Dictionary(grouping: mix, by: \.kind)
      .sorted { $0.key < $1.key }
      .map { kind, packs in
        let share = packs.reduce(0) { $0 + $1.share }.formatted(.percent.precision(.fractionLength(0)))
        return switch kind {
        case .main: String(localized: "\(share) \(packs.map { "\($0.name)s" }.formatted())")
        case .collector: String(localized: "\(share) Collector Boosters")
        case .other: String(localized: "\(share) other packs")
        }
      }
    return String(localized: "A guess across \(setName)'s packs, taking the packs opened to be about \(parts.formatted()). Each product's own odds are below.")
  }

  /// "~168 packs": about how many packs it takes to open one. "Every pack" for a card no pack is
  /// without.
  private static func packs(_ count: Int) -> String {
    count == 1 ? String(localized: "Every pack") : String(localized: "~\(count.pullOddsDenominator()) packs")
  }

  /// The request the on-device model answers: the definition, the tile's value on this card, every
  /// fact about the card, and what to explain.
  func insightPrompt(card: Card) -> String {
    """
    The detail: \(insightTitle)
    Definition: \(insightSummary)
    \(insightDetail(card: card))

    The card:
    \(card.insightDescription)

    \(insightTask)
    """
  }

  private func insightDetail(card: Card) -> String {
    switch self {
    case let .set(code, rarity, _):
      "This printing is from \(card.setName) (\(code.uppercased())), released \(card.releasedAt), at \(rarity.rawValue) rarity."
    case let .pullOdds(odds, _, _):
      oddsDetail(odds)
    case let .collectorNumber(number):
      // Said outright: left to itself, the model read number 100 as the card's hundredth version.
      "This printing is number \(number) in \(card.setName)'s list of cards, its place in the set, not a count of versions. It is"
        + (card.treatments.isEmpty ? " a regular printing." : " a \(card.treatments.joined(separator: ", ").lowercased()) printing.")
    case .colorIdentity:
      "Its color identity is \(card.colorIdentity.isEmpty ? "colorless" : card.colorIdentity.map(\.name).joined(separator: ", "))."
    case let .manaValue(value):
      "Its mana value is \(manaValue(value))."
    case let .loyalty(counters):
      "It enters with \(counters) loyalty."
    case let .powerToughness(power, toughness):
      "It is a \(power)/\(toughness)."
    }
  }

  private var insightTask: String {
    switch self {
    case .set:
      "Explain what the set and its rarity tell a player about this card."
    case .pullOdds:
      // Even labelled, the model misquotes them and makes up percentages of its own. The reader has
      // every exact number in the facts above the explanation, so the model only says what they mean.
      "Explain in plain words what odds like these mean for someone hoping to open this printing: whether opening packs for it is realistic, and how the products and finishes compare. The reader can already see the exact odds, so do not repeat, round or calculate any number or percentage."
    case .collectorNumber:
      "Explain what this collector number tells a collector about this printing."
    case .colorIdentity:
      "Explain this card's color identity and which Commander decks it can be played in."
    case .manaValue:
      "Explain this card's mana value and where it matters when playing the card."
    case .loyalty:
      "Explain what this starting loyalty means for how the planeswalker plays."
    case .powerToughness:
      "Explain what this power and toughness mean for how the creature fights."
    }
  }

  /// Every number carries its finish in words next to it: given "1 in 168; as a foil 1 in 2,100;
  /// not foil 1 in 182", the model called the 168 the non-foil odds. The product that gives the card
  /// up most often is worked out here rather than left to the model.
  private func oddsDetail(_ odds: CardPullOdds) -> String {
    // Called products by the definition, the model took them for sets and bundles.
    var lines = ["Each line below is a kind of booster pack sold for this one set. Odds of opening this exact printing:"]
    if let estimate = odds.estimatePacks {
      lines.append("- Estimated across every kind of \(odds.headline.setName) pack, weighted by a guess at how many of each are opened: one pack in \(estimate.formatted()).")
    }
    for product in odds.products {
      var line = "- \(product.setName) \(product.name): one pack in \((product.packs ?? 1).formatted()) holds it in either finish."
      if let foil = product.foilPacks { line += " Counting only foils: one pack in \(foil.formatted())." }
      if let nonFoil = product.nonFoilPacks { line += " Counting only non-foils: one pack in \(nonFoil.formatted())." }
      lines.append(line)
    }
    if let best = odds.products.max(by: { $0.chance < $1.chance }) {
      lines.append("It turns up most often in the \(best.setName) \(best.name).")
    }
    return lines.joined(separator: "\n")
  }

  /// The row passes mana value on as "3.0"; it reads as "3".
  private func manaValue(_ value: String) -> String {
    Double(value).map { $0.formatted() } ?? value
  }

  private func releaseDate(of card: Card) -> String {
    guard let date = try? Date.ISO8601FormatStyle().year().month().day().parse(card.releasedAt) else {
      return card.releasedAt
    }
    // Read and written in UTC: a calendar date, which in local time lands a day early west of it.
    return date.formatted(Date.FormatStyle(date: .long, time: .omitted, timeZone: .gmt))
  }
}
