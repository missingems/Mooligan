import DesignComponents
import ScryfallKit
import SwiftUI
import UIKit

/// "~168 packs" lettered like a puffy sticker: two lines of heavy rounded type, blown up with light
/// along their upper edges and shade along their lower ones, in a glossy dark outline on a white
/// die-cut, stuck on a little crooked. The number is filled with its card's rarity colours, and a
/// reflection slides over the lot as the phone moves.
///
/// The lettering is drawn from its glyph outlines, so every edge is a true curve: the outlines are
/// the letters stroked with round joins, and the puffiness is each shape's own silhouette, nudged
/// and blurred, laid inside it as light and shade.
struct OddsSticker: View, Equatable {
  let packs: Int
  let rarity: Card.Rarity
  let size: CGFloat
  /// Degrees it is stuck on crooked by.
  let tilt: Double
  /// The sticker's back: its white backing alone, for when it is turned away mid-spin.
  var isBack = false

  nonisolated static func == (lhs: OddsSticker, rhs: OddsSticker) -> Bool {
    lhs.packs == rhs.packs && lhs.rarity == rhs.rarity && lhs.size == rhs.size && lhs.tilt == rhs.tilt
      && lhs.isBack == rhs.isBack
  }

  var body: some View {
    let shapes = shapes

    Canvas { context, _ in
      let colours = rarityColours(in: context.environment)

      // The die-cut, lifted off the page by its shadow, with a little shade inside its lower edge.
      context.drawLayer { layer in
        layer.addFilter(.shadow(color: .black.opacity(0.3), radius: size * 0.06, y: size * 0.04))
        layer.fill(shapes.border, with: .color(.white))
      }
      shade(shapes.border, in: context, depth: size * 0.07, with: Color(white: 0.84))
      guard isBack == false else { return }

      context.fill(shapes.outline, with: .color(Color(red: 0.06, green: 0.07, blue: 0.09)))
      light(shapes.outline, in: context, depth: size * 0.05, opacity: 0.3)

      context.fill(shapes.words, with: .color(Color(red: 0.98, green: 0.97, blue: 0.94)))
      // Across the number from corner to corner, the way the set tile lays its rarity gradient.
      let number = shapes.number.boundingRect
      context.fill(
        shapes.number,
        with: .linearGradient(
          Gradient(colors: colours),
          startPoint: CGPoint(x: number.minX, y: number.minY),
          endPoint: CGPoint(x: number.maxX, y: number.maxY)
        )
      )

      // Each line's shade is a deeper tone of its own colour, as a blown-up shape darkens into its
      // curve, rather than grey laid over it.
      shade(shapes.words, in: context, depth: size * 0.1, with: Color(red: 0.8, green: 0.74, blue: 0.64))
      shade(shapes.number, in: context, depth: size * 0.12, with: colours.first ?? .gray)
      light(shapes.letters, in: context, depth: size * 0.1, opacity: 0.3)
      // A thin, bright glint on the rims, where a glossy surface catches the light hardest.
      light(shapes.letters, in: context, depth: size * 0.04, opacity: 0.85)
    }
    .frame(width: shapes.size.width, height: shapes.size.height)
    .overlay {
      MotionSheen()
        .mask { shapes.border }
    }
    .rotationEffect(.degrees(tilt))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(packs == 1 ? String(localized: "Every pack") : String(localized: "About \(denominator) packs")))
  }

  /// The two lines of lettering laid out, centred over one another, and the outline and die-cut
  /// around them, in the sticker's own space.
  private var shapes: (words: Path, number: Path, letters: Path, outline: Path, border: Path, size: CGSize) {
    // The number leads, with what it counts small under it: "~179" over "packs".
    let lines = [
      Path(lettering: number, font: Self.font(size: size * 1.1)),
      Path(lettering: packs == 1 ? String(localized: "pack") : String(localized: "packs"), font: Self.font(size: size * 0.62)),
    ]
    let bounds = lines.map(\.boundingRect)

    // Room for the die-cut beyond the outline, and for the shadow under it.
    let margin = size * 0.36
    let gap = size * 0.08
    let width = (bounds.map(\.width).max() ?? 0) + margin * 2
    let height = bounds.reduce(0) { $0 + $1.height } + gap * CGFloat(lines.count - 1) + margin * 2

    var placed: [Path] = []
    var y = margin
    for (line, lineBounds) in zip(lines, bounds) {
      placed.append(line.offsetBy(dx: (width - lineBounds.width) / 2 - lineBounds.minX, dy: y - lineBounds.minY))
      y += lineBounds.height + gap
    }

    let words = placed[1]
    var letters = words
    letters.addPath(placed[0])
    // Round the letters with their holes closed, so the holes come out solid black.
    let solid = letters.withoutCounters
    let outline = solid.union(
      solid.strokedPath(StrokeStyle(lineWidth: size * 0.26, lineCap: .round, lineJoin: .round))
    )
    let border = solid.union(
      solid.strokedPath(StrokeStyle(lineWidth: size * 0.5, lineCap: .round, lineJoin: .round))
    )
    return (words, placed[0], letters, outline, border, CGSize(width: width, height: height))
  }

  /// Shade inside `shape`'s lower right edges: the band between the shape and itself nudged up and
  /// left, blurred soft and multiplied into what is already drawn there.
  private func shade(_ shape: Path, in context: GraphicsContext, depth: CGFloat, with colour: Color) {
    var lower = Path(shape.boundingRect.insetBy(dx: -depth * 4, dy: -depth * 4))
    lower.addPath(shape.offsetBy(dx: -depth * 0.8, dy: -depth))

    var context = context
    context.clip(to: shape)
    context.blendMode = .multiply
    context.drawLayer { band in
      band.addFilter(.blur(radius: depth * 0.8))
      band.fill(lower, with: .color(colour), style: FillStyle(eoFill: true))
    }
  }

  /// Light inside `shape`'s upper left edges, the same band the other way.
  private func light(_ shape: Path, in context: GraphicsContext, depth: CGFloat, opacity: Double) {
    var upper = Path(shape.boundingRect.insetBy(dx: -depth * 4, dy: -depth * 4))
    upper.addPath(shape.offsetBy(dx: depth * 0.7, dy: depth))

    var context = context
    context.clip(to: shape)
    context.drawLayer { band in
      band.addFilter(.blur(radius: depth * 0.6))
      band.fill(upper, with: .color(.white.opacity(opacity)), style: FillStyle(eoFill: true))
    }
  }

  private var denominator: String {
    packs.pullOddsDenominator()
  }

  /// "~179", rounded as the odds are; "Every" for a card no pack is without.
  private var number: String {
    packs == 1 ? String(localized: "Every") : "~\(denominator)"
  }

  /// SF Pro Rounded at its heaviest.
  private static func font(size: CGFloat) -> UIFont {
    let font = UIFont.systemFont(ofSize: size, weight: .black)
    guard let rounded = font.fontDescriptor.withDesign(.rounded) else { return font }
    return UIFont(descriptor: rounded, size: size)
  }

  /// The set tile's rarity colours as the tile shows them. The assets are see-through, and read as
  /// light gold or silver only over the light glass beneath; drawn as they are over the sticker's
  /// dark outline they came out brown and slate. So each is laid over white first. The rarities the
  /// app has no colours for take their set symbol's: graphite for common, purple for special.
  private func rarityColours(in environment: EnvironmentValues) -> [Color] {
    guard let names = rarity.colorNames else {
      return switch rarity {
      case .common:
        [Color(white: 0.3), Color(white: 0.62), Color(white: 0.3)]
      case .special:
        [
          Color(red: 0.42, green: 0.25, blue: 0.62),
          Color(red: 0.72, green: 0.56, blue: 0.9),
          Color(red: 0.42, green: 0.25, blue: 0.62),
        ]
      default:
        [Color(red: 0.98, green: 0.74, blue: 0.1)]
      }
    }

    return names.map { name in
      var colour = Color(name, bundle: DesignComponentsResources.bundle).resolve(in: environment)
      let opacity = Double(colour.opacity)
      colour.opacity = 1
      return Color(colour).mix(with: .white, by: 1 - opacity)
    }
  }
}
