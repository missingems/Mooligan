import Foundation

/// Trimmed slices of MTGJSON's real Bloomburrow (BLB) and Bloomburrow Commander (BLC) set files.
///
/// Every product, pack layout and sheet is kept, with each sheet's real `totalWeight`, but only the
/// cards the tests look at are left on the sheets. Because a card's odds are its own weight against
/// the sheet's total, trimming the others away leaves those cards' odds exactly as the full file
/// gives them: the numbers the tests expect were worked out from the untrimmed files.
enum PullOddsFixtures {
  /// Maha, Its Feathers Night (#100, mythic) and its borderless printing (#289), and Mabel, Heir to
  /// Cragflame (#224, rare). Includes the Arena and sample products, which must be ignored.
  static let bloomburrow = """
    {
     "data": {
      "name": "Bloomburrow",
      "booster": {
       "play": {
        "name": "Bloomburrow Play Booster",
        "boostersTotalWeight": 1000,
        "boosters": [
         {
          "contents": {
           "common": 7,
           "foil": 1,
           "land": 1,
           "rareMythicWithShowcase": 1,
           "uncommon": 3,
           "wildcard": 1
          },
          "weight": 788
         },
         {
          "contents": {
           "common": 6,
           "foil": 1,
           "land": 1,
           "rareMythicWithShowcase": 1,
           "specialGuest": 1,
           "uncommon": 3,
           "wildcard": 1
          },
          "weight": 12
         },
         {
          "contents": {
           "common": 7,
           "foil": 1,
           "foilLand": 1,
           "rareMythicWithShowcase": 1,
           "uncommon": 3,
           "wildcard": 1
          },
          "weight": 197
         },
         {
          "contents": {
           "common": 6,
           "foil": 1,
           "foilLand": 1,
           "rareMythicWithShowcase": 1,
           "specialGuest": 1,
           "uncommon": 3,
           "wildcard": 1
          },
          "weight": 3
         }
        ],
        "sheets": {
         "common": {
          "foil": false,
          "totalWeight": 81,
          "cards": {}
         },
         "foil": {
          "foil": true,
          "totalWeight": 5670000,
          "cards": {
           "1f64bc9e-23c2-5f50-a6e4-2d84b4fee207": 2700,
           "7d22b1e6-c247-511e-86c3-8c27aa87b17e": 5400,
           "ce805977-0855-5e86-9b75-bca727f57c26": 1350
          }
         },
         "foilLand": {
          "foil": true,
          "totalWeight": 50,
          "cards": {}
         },
         "land": {
          "foil": false,
          "totalWeight": 50,
          "cards": {}
         },
         "rareMythicWithShowcase": {
          "foil": false,
          "totalWeight": 840,
          "cards": {
           "1f64bc9e-23c2-5f50-a6e4-2d84b4fee207": 4,
           "7d22b1e6-c247-511e-86c3-8c27aa87b17e": 8,
           "ce805977-0855-5e86-9b75-bca727f57c26": 2
          }
         },
         "specialGuest": {
          "foil": false,
          "totalWeight": 10,
          "cards": {}
         },
         "uncommon": {
          "foil": false,
          "totalWeight": 100,
          "cards": {}
         },
         "wildcard": {
          "foil": false,
          "totalWeight": 22680000,
          "cards": {
           "1f64bc9e-23c2-5f50-a6e4-2d84b4fee207": 16740,
           "7d22b1e6-c247-511e-86c3-8c27aa87b17e": 33480,
           "ce805977-0855-5e86-9b75-bca727f57c26": 8370
          }
         }
        }
       },
       "collector": {
        "name": "Bloomburrow Collector Booster",
        "boostersTotalWeight": 71,
        "boosters": [
         {
          "contents": {
           "commanderCard": 1,
           "foilCommon": 5,
           "foilLand": 1,
           "foilRareMythic": 1,
           "foilShowcaseRareMythic": 1,
           "foilUncommon": 4,
           "showcaseRareMythic": 2
          },
          "weight": 69
         },
         {
          "contents": {
           "foilCommander": 1,
           "foilCommon": 5,
           "foilLand": 1,
           "foilRareMythic": 1,
           "foilShowcaseRareMythic": 1,
           "foilUncommon": 4,
           "showcaseRareMythic": 2
          },
          "weight": 2
         }
        ],
        "sheets": {
         "commanderCard": {
          "foil": false,
          "totalWeight": 69,
          "cards": {
           "f0201e5d-1959-5e62-ad82-762210059d9c": 1
          }
         },
         "foilCommander": {
          "foil": true,
          "totalWeight": 4,
          "cards": {}
         },
         "foilCommon": {
          "foil": true,
          "totalWeight": 81,
          "cards": {}
         },
         "foilLand": {
          "foil": true,
          "totalWeight": 50,
          "cards": {}
         },
         "foilRareMythic": {
          "foil": true,
          "totalWeight": 140,
          "cards": {
           "1f64bc9e-23c2-5f50-a6e4-2d84b4fee207": 1,
           "7d22b1e6-c247-511e-86c3-8c27aa87b17e": 2
          }
         },
         "foilShowcaseRareMythic": {
          "foil": true,
          "totalWeight": 3586,
          "cards": {
           "ce805977-0855-5e86-9b75-bca727f57c26": 22
          }
         },
         "foilUncommon": {
          "foil": true,
          "totalWeight": 100,
          "cards": {}
         },
         "showcaseRareMythic": {
          "foil": false,
          "totalWeight": 304,
          "cards": {
           "ce805977-0855-5e86-9b75-bca727f57c26": 2
          }
         }
        }
       },
       "play-arena": {
        "name": "Bloomburrow Arena Play Booster",
        "boostersTotalWeight": 200,
        "boosters": [
         {
          "contents": {
           "common": 7,
           "foilReplacement": 1,
           "rareMythic": 1,
           "uncommon": 3,
           "wildcard": 1
          },
          "weight": 197
         },
         {
          "contents": {
           "common": 6,
           "foilReplacement": 1,
           "rareMythic": 1,
           "specialGuest": 1,
           "uncommon": 3,
           "wildcard": 1
          },
          "weight": 3
         }
        ],
        "sheets": {
         "common": {
          "foil": false,
          "totalWeight": 81,
          "cards": {}
         },
         "foilReplacement": {
          "foil": false,
          "totalWeight": 2835000,
          "cards": {
           "1f64bc9e-23c2-5f50-a6e4-2d84b4fee207": 2025,
           "7d22b1e6-c247-511e-86c3-8c27aa87b17e": 4050
          }
         },
         "rareMythic": {
          "foil": false,
          "totalWeight": 140,
          "cards": {
           "1f64bc9e-23c2-5f50-a6e4-2d84b4fee207": 1,
           "7d22b1e6-c247-511e-86c3-8c27aa87b17e": 2
          }
         },
         "specialGuest": {
          "foil": false,
          "totalWeight": 10,
          "cards": {}
         },
         "uncommon": {
          "foil": false,
          "totalWeight": 100,
          "cards": {}
         },
         "wildcard": {
          "foil": false,
          "totalWeight": 11340000,
          "cards": {
           "1f64bc9e-23c2-5f50-a6e4-2d84b4fee207": 12555,
           "7d22b1e6-c247-511e-86c3-8c27aa87b17e": 25110
          }
         }
        }
       },
       "collector-sample": {
        "name": "Bloomburrow Collector Sample Booster",
        "boostersTotalWeight": 3,
        "boosters": [
         {
          "contents": {
           "foilUncommon": 1,
           "showcaseRareMythic": 1
          },
          "weight": 2
         },
         {
          "contents": {
           "foilShowcaseRareMythic": 1,
           "foilUncommon": 1
          },
          "weight": 1
         }
        ],
        "sheets": {
         "foilShowcaseRareMythic": {
          "foil": true,
          "totalWeight": 312,
          "cards": {
           "ce805977-0855-5e86-9b75-bca727f57c26": 2,
           "f0201e5d-1959-5e62-ad82-762210059d9c": 2
          }
         },
         "foilUncommon": {
          "foil": true,
          "totalWeight": 100,
          "cards": {}
         },
         "showcaseRareMythic": {
          "foil": false,
          "totalWeight": 312,
          "cards": {
           "ce805977-0855-5e86-9b75-bca727f57c26": 2,
           "f0201e5d-1959-5e62-ad82-762210059d9c": 2
          }
         }
        }
       }
      },
      "cards": [
       {
        "uuid": "1f64bc9e-23c2-5f50-a6e4-2d84b4fee207",
        "rarity": "mythic",
        "identifiers": {
         "scryfallId": "cf3320ec-c4e8-405a-982d-e009c58c9e21"
        }
       },
       {
        "uuid": "7d22b1e6-c247-511e-86c3-8c27aa87b17e",
        "rarity": "rare",
        "identifiers": {
         "scryfallId": "be6627fd-729d-44f2-b6bf-5299f49d1e3d"
        }
       },
       {
        "uuid": "ce805977-0855-5e86-9b75-bca727f57c26",
        "rarity": "mythic",
        "identifiers": {
         "scryfallId": "bfd53428-56c3-4c99-828d-665e3c2d15a8"
        }
       }
      ]
     }
    }
    """

  /// Bello, Bard of the Brambles (#1, mythic). The commander set has no boosters of its own; its
  /// cards are opened in Bloomburrow's Collector Booster, on the `commanderCard` sheet.
  static let bloomburrowCommander = """
    {
     "data": {
      "name": "Bloomburrow Commander",
      "booster": null,
      "cards": [
       {
        "uuid": "f0201e5d-1959-5e62-ad82-762210059d9c",
        "rarity": "mythic",
        "identifiers": {
         "scryfallId": "31e4b7a1-b377-49d2-a92e-4bcb0db35f16"
        }
       }
      ]
     }
    }
    """

  static let mahaID = UUID(uuidString: "cf3320ec-c4e8-405a-982d-e009c58c9e21")!
  static let borderlessMahaID = UUID(uuidString: "bfd53428-56c3-4c99-828d-665e3c2d15a8")!
  static let mabelID = UUID(uuidString: "be6627fd-729d-44f2-b6bf-5299f49d1e3d")!
  static let belloID = UUID(uuidString: "31e4b7a1-b377-49d2-a92e-4bcb0db35f16")!
}
