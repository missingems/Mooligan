@testable import Networking
import Foundation
import ScryfallKit
import Testing

/// Covers the MTGJSON parsing/aggregation `MTGJSONBoosterOddsSource` runs
/// against real per-set booster data.
///
/// The fixture below is not synthetic: it is a trimmed slice of Murders at
/// Karlov Manor's actual MTGJSON file (fetched and inspected by hand), keeping
/// every sheet the `play` booster config uses but only a few cards per rarity
/// per sheet. The expected numbers are what summing that trimmed slice's real
/// weights by hand produces — this is checking the aggregation logic against
/// real data shaped exactly like what ships in production, not against
/// invented percentages.
struct MTGJSONBoosterOddsSourceTests {
  private func decode(_ json: String) -> MTGJSONSetData {
    let data = Data(json.utf8)
    return try! JSONDecoder().decode(MTGJSONSetFile.self, from: data).data
  }

  /// Trimmed from MKM: `wildcard`, `foil` and `rareMythicWithShowcase` are the
  /// three sheets the roller needs; `commonWithShowcase` is a distractor that
  /// must be ignored by name, proving the matcher doesn't grab just anything.
  private let mkmFixture = """
    {
      "data": {
        "booster": {
          "play": {
            "sheets": {
              "wildcard": {
                "cards": {
                  "0031ac0c-95db-5dc6-aac1-311ea9649bf7": 879660,
                  "026a8fcb-c5db-50c9-9c9c-13db04701f21": 586440,
                  "02c11a99-531f-509c-8878-760e2769a639": 879660,
                  "014eac08-1133-53c4-a8bf-b8b6308cfab5": 568400,
                  "029f1c1d-a7e0-55a6-ac90-09d48c0cc414": 852600,
                  "038d09bf-3d2f-557e-b172-784071285d45": 852600,
                  "02d27163-fd8f-516a-94cf-cfc735ae38f1": 698544,
                  "088e040c-48d4-5c6f-ba03-89723fddea88": 698544,
                  "099c2ae3-7193-53d2-81b3-a8e42fad591b": 2095632,
                  "07a1f955-15ca-5f8f-80c6-611edac7381f": 293220,
                  "0face518-45ff-5254-a9aa-b7b3ca850303": 146610,
                  "17e08a2c-ca21-5c38-bbed-ded812de9974": 73305
                },
                "foil": false
              },
              "foil": {
                "cards": {
                  "0031ac0c-95db-5dc6-aac1-311ea9649bf7": 24300,
                  "026a8fcb-c5db-50c9-9c9c-13db04701f21": 16200,
                  "02c11a99-531f-509c-8878-760e2769a639": 24300,
                  "014eac08-1133-53c4-a8bf-b8b6308cfab5": 92800,
                  "029f1c1d-a7e0-55a6-ac90-09d48c0cc414": 139200,
                  "038d09bf-3d2f-557e-b172-784071285d45": 139200,
                  "02d27163-fd8f-516a-94cf-cfc735ae38f1": 20736,
                  "088e040c-48d4-5c6f-ba03-89723fddea88": 20736,
                  "099c2ae3-7193-53d2-81b3-a8e42fad591b": 62208,
                  "07a1f955-15ca-5f8f-80c6-611edac7381f": 8100,
                  "0face518-45ff-5254-a9aa-b7b3ca850303": 4050,
                  "17e08a2c-ca21-5c38-bbed-ded812de9974": 2025
                },
                "foil": true
              },
              "rareMythicWithShowcase": {
                "cards": {
                  "0031ac0c-95db-5dc6-aac1-311ea9649bf7": 12,
                  "026a8fcb-c5db-50c9-9c9c-13db04701f21": 8,
                  "02c11a99-531f-509c-8878-760e2769a639": 12,
                  "07a1f955-15ca-5f8f-80c6-611edac7381f": 4,
                  "0face518-45ff-5254-a9aa-b7b3ca850303": 2,
                  "17e08a2c-ca21-5c38-bbed-ded812de9974": 1
                },
                "foil": false
              },
              "commonWithShowcase": {
                "cards": {
                  "014eac08-1133-53c4-a8bf-b8b6308cfab5": 2,
                  "029f1c1d-a7e0-55a6-ac90-09d48c0cc414": 3,
                  "038d09bf-3d2f-557e-b172-784071285d45": 3
                },
                "foil": false
              }
            }
          }
        },
        "cards": [
          { "uuid": "0031ac0c-95db-5dc6-aac1-311ea9649bf7", "rarity": "rare" },
          { "uuid": "026a8fcb-c5db-50c9-9c9c-13db04701f21", "rarity": "rare" },
          { "uuid": "02c11a99-531f-509c-8878-760e2769a639", "rarity": "rare" },
          { "uuid": "014eac08-1133-53c4-a8bf-b8b6308cfab5", "rarity": "common" },
          { "uuid": "029f1c1d-a7e0-55a6-ac90-09d48c0cc414", "rarity": "common" },
          { "uuid": "038d09bf-3d2f-557e-b172-784071285d45", "rarity": "common" },
          { "uuid": "02d27163-fd8f-516a-94cf-cfc735ae38f1", "rarity": "uncommon" },
          { "uuid": "088e040c-48d4-5c6f-ba03-89723fddea88", "rarity": "uncommon" },
          { "uuid": "099c2ae3-7193-53d2-81b3-a8e42fad591b", "rarity": "uncommon" },
          { "uuid": "07a1f955-15ca-5f8f-80c6-611edac7381f", "rarity": "mythic" },
          { "uuid": "0face518-45ff-5254-a9aa-b7b3ca850303", "rarity": "mythic" },
          { "uuid": "17e08a2c-ca21-5c38-bbed-ded812de9974", "rarity": "mythic" }
        ]
      }
    }
    """

  private func weight(_ weights: [RarityWeight], for rarity: Card.Rarity) -> Double? {
    weights.first { $0.rarity == rarity }?.weight
  }

  @Test("the mythic rate comes from the real rareMythic sheet's weights")
  func recoversMythicChance() {
    let odds = decode(mkmFixture).odds(for: .play)
    #expect(abs(odds.mythicChance - 0.1795) < 0.001)
  }

  @Test("the plain wildcard slot's rarity split matches the real sheet")
  func recoversWildcardWeights() {
    let odds = decode(mkmFixture).odds(for: .play)

    #expect(abs((weight(odds.wildcardWeights, for: .common) ?? 0) - 0.2636) < 0.001)
    #expect(abs((weight(odds.wildcardWeights, for: .uncommon) ?? 0) - 0.4049) < 0.001)
    #expect(abs((weight(odds.wildcardWeights, for: .rare) ?? 0) - 0.2720) < 0.001)
    #expect(abs((weight(odds.wildcardWeights, for: .mythic) ?? 0) - 0.0595) < 0.001)
  }

  @Test("the foil wildcard slot draws from its own, different sheet")
  func foilWildcardIsItsOwnDistribution() {
    let odds = decode(mkmFixture).odds(for: .play)

    #expect(abs((weight(odds.foilWildcardWeights, for: .common) ?? 0) - 0.6702) < 0.001)
    #expect(abs((weight(odds.foilWildcardWeights, for: .rare) ?? 0) - 0.1170) < 0.001)
    // The two slots must not collapse to the same table — that was the bug.
    #expect(odds.wildcardWeights != odds.foilWildcardWeights)
  }

  @Test("a booster kind absent from the file falls back entirely")
  func missingKindFallsBack() {
    let odds = decode(mkmFixture).odds(for: .collector)
    #expect(odds == .fallback)
  }

  @Test("a play request with no play key borrows draft's real numbers")
  func playBorrowsDraftWhenPlayIsAbsent() {
    let json = mkmFixture.replacingOccurrences(of: "\"play\":", with: "\"draft\":")
    let odds = decode(json).odds(for: .play)

    #expect(odds != .fallback)
    #expect(abs(odds.mythicChance - 0.1795) < 0.001)
  }

  @Test("a set with no booster field at all is entirely fallback")
  func noBoosterFieldIsFallback() {
    let json = """
      { "data": { "cards": [] } }
      """
    #expect(decode(json).odds(for: .play) == .fallback)
  }

  @Test("multiple rare/mythic sheets refuse to guess and fall back")
  func ambiguousRareMythicSheetsFallBack() {
    // Mirrors Collector Boosters, which name several treatment-specific
    // rare/mythic sheets rather than one: each has its own real rate, so
    // there is no single number to average them into.
    let json = """
      {
        "data": {
          "booster": {
            "play": {
              "sheets": {
                "rareMythicMain": {
                  "cards": { "a": 1 },
                  "foil": false
                },
                "rareMythicCommander": {
                  "cards": { "b": 1 },
                  "foil": false
                }
              }
            }
          },
          "cards": [
            { "uuid": "a", "rarity": "rare" },
            { "uuid": "b", "rarity": "mythic" }
          ]
        }
      }
      """
    let odds = decode(json).odds(for: .play)
    #expect(odds.mythicChance == BoosterPackOdds.fallback.mythicChance)
  }

  @Test("a sheet named right but foiled wrong is not mistaken for its counterpart")
  func foilFlagMismatchIsRejected() {
    // A sheet literally named "wildcard" but marked foil in the data would be
    // a contradiction the parser should not paper over by matching on name alone.
    let json = """
      {
        "data": {
          "booster": {
            "play": {
              "sheets": {
                "wildcard": {
                  "cards": { "a": 1 },
                  "foil": true
                }
              }
            }
          },
          "cards": [
            { "uuid": "a", "rarity": "common" }
          ]
        }
      }
      """
    let odds = decode(json).odds(for: .play)
    #expect(odds.wildcardWeights == BoosterPackOdds.fallback.wildcardWeights)
  }
}
