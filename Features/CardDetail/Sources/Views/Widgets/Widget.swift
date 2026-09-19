import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

struct Widget: View {
  let kind: InformationWidget
  /// The tile standing alone as a badge, as the explanation shows it: without its name, which the
  /// title under it already gives, and on a solid face rather than glass, because the badge is
  /// turned in 3D and glass cannot be (it falls back to a flat grey).
  var isBadge = false

  /// The sticker's lettering, which grows with the reader's text size as the other tiles' text does.
  @ScaledMetric(relativeTo: .body) private var stickerSize = 18.0

  var body: some View {
    switch kind {
    case let .powerToughness(power, toughness):
      powerToughnessView(power: power, toughness: toughness)

    case let .set(code, rarity, iconURL):
      setCodeView(code, rarity: rarity, iconURL: iconURL)

    case let .pullOdds(odds, rarity, tilt):
      pullOddsView(odds, rarity: rarity, tilt: tilt)

    case let .colorIdentity(manaIdentity):
      manaIdentityView(manaIdentity)

    case let .collectorNumber(number):
      collectionNumberView(number)

    case let .loyalty(counters):
      loyaltyWidgetView(counters)

    case let .manaValue(value):
      manaValueView(value)
    }
  }
}

extension Widget {
  @ContentBuilder private func powerToughnessView(
    power: String?,
    toughness: String?
  ) -> some View {
    if let power, let toughness {
      VStack(alignment: .center, spacing: 3) {
        tile {
          Image("power", bundle: DesignComponentsResources.bundle)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 15)
            .foregroundStyle(.primary)

          Text("\(power)/\(toughness)")
            .font(.body)
            .fontDesign(.serif)

          Image("toughness", bundle: DesignComponentsResources.bundle)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 15)
            .foregroundStyle(.primary)
        }

        caption(String(localized: "Power\nToughness"))
      }
    }
  }

  @ContentBuilder private func manaIdentityView(_ identity: [String]) -> some View {
    if identity.isEmpty == false {
      VStack(alignment: .center, spacing: 3.0) {
        tile {
          ManaView(identity: identity, size: CGSize(width: 21, height: 21))?.offset(y: -1)
        }

        caption(String(localized: "Color\nIdentity"))
      }
    }
  }

  @ContentBuilder private func loyaltyWidgetView(_ counters: String?) -> some View {
    if let counters {
      VStack(alignment: .center, spacing: 3.0) {
        tile {
          ZStack(alignment: .center) {
            Image("loyalty", bundle: DesignComponentsResources.bundle)
              .resizable()
              .renderingMode(.template)
              .aspectRatio(contentMode: .fit)
              .frame(width: 50)
              .tint(.accentColor)

            Text(counters)
              .font(.body)
              .fontDesign(.serif)
              .offset(y: 1)
              .colorInvert()
          }
        }

        caption(String(localized: "Loyalty\nCounters"))
      }
    }
  }

  @ContentBuilder private func collectionNumberView(_ collectorNumber: String?) -> some View {
    if let collectorNumber {
      VStack(alignment: .center, spacing: 3.0) {
        tile {
          Text("#\(collectorNumber)".uppercased()).font(.body).fontDesign(.serif)
        }

        caption(String(localized: "Collector\nNumber"))
      }
    }
  }

  @ContentBuilder private func setCodeView(
    _ code: String?,
    rarity: Card.Rarity,
    iconURL: URL?
  ) -> some View {
    let colors = rarity.colorNames?.map({ Color($0, bundle: DesignComponentsResources.bundle)})

    if let code {
      VStack(alignment: .center, spacing: 3.0) {
        surface(
          HStack(spacing: 3.0) {
            IconLazyImage(iconURL, tintColor: .primary).frame(width: 25, height: 25)
            Text(code.uppercased())
              .font(.body)
              .fontWeight(.medium)
              .fontWidth(.condensed)
          }
          .frame(minWidth: 66, minHeight: 34)
          .padding(EdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11)),
          glass: .clear.interactive(),
          fill: colors.map {
            AnyShapeStyle(LinearGradient(colors: $0, startPoint: .topLeading, endPoint: .bottomTrailing))
          } ?? AnyShapeStyle(Color(.systemFill))
        )

        caption("\(rarity.rawValue.capitalized)\n ")
      }
    }
  }

  /// The estimate across the set's packs, the one figure that takes every product into account.
  private func pullOddsView(_ odds: CardPullOdds, rarity: Card.Rarity, tilt: Double) -> some View {
    VStack(alignment: .center, spacing: 3.0) {
      tile {
        // As wide as the odds need, like any tile, but held to the other tiles' height: the sticker
        // stands a little proud of its glass, the way one slapped on would, without making the row
        // any taller.
        OddsSticker(packs: odds.estimatePacks ?? 1, rarity: rarity, size: stickerSize, tilt: tilt)
          .equatable()
          .frame(height: stickerSize / 18 * 34)
      }

      caption(String(localized: "Pull\nRate"))
    }
  }

  @ContentBuilder private func manaValueView(_ manaValue: String?) -> some View {
    if let manaValue {
      VStack(alignment: .center, spacing: 3.0) {
        tile {
          Text(manaValue)
            .font(.body)
            .fontDesign(.monospaced)
        }

        caption(String(localized: "Mana\nValue"))
      }
    }
  }
}

extension Widget {
  /// The tile's name under it, in two lines like every other tile's.
  @ViewBuilder private func caption(_ text: String) -> some View {
    if isBadge == false {
      Text(text)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity, alignment: .center)
    }
  }
}

extension Widget {
  @ContentBuilder private func tile(@ContentBuilder content: () -> some View) -> some View {
    surface(
      HStack(spacing: 5.0) {
        content()
      }
      .frame(minWidth: 66, minHeight: 34)
      .padding(EdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11)),
      glass: .regular.interactive()
    )
  }

  /// What the tile stands on: glass in the row, over `fill` where the tile has a colour of its own,
  /// as the set tile has its rarity's. A badge gets a solid enamel face instead, with a rim lit from
  /// above: it spins and sways in 3D, and glass under a 3D turn falls back to a flat grey.
  @ViewBuilder private func surface(_ content: some View, glass: Glass, fill: AnyShapeStyle? = nil) -> some View {
    if isBadge {
      content.background {
        Capsule()
          .fill(fill ?? AnyShapeStyle(LinearGradient(
            colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
            startPoint: .top,
            endPoint: .bottom
          )))
          .overlay {
            Capsule().strokeBorder(
              LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
              lineWidth: 1.5
            )
          }
          .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
      }
    } else if let fill {
      content
        .glassEffect(glass)
        .background(fill, in: .capsule)
    } else {
      content.glassEffect(glass)
    }
  }
}
