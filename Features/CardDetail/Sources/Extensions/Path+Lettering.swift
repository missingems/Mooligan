import CoreText
import SwiftUI
import UIKit

extension Path {
  /// The outlines of `text`'s glyphs set in `font`, with the top of the font's ascent at y = 0.
  ///
  /// A path rather than a `Text`, so the lettering can be stroked and shaded like any shape: text
  /// has no stroke of its own, and outlines faked by stamping copies of it came out ragged.
  init(lettering text: String, font: UIFont) {
    self.init()
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
    guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return }

    for run in runs {
      // The run's own font, which differs from `font` wherever a glyph had to fall back to another.
      let attributes = CTRunGetAttributes(run) as NSDictionary
      guard
        let value = attributes[kCTFontAttributeName],
        CFGetTypeID(value as CFTypeRef) == CTFontGetTypeID()
      else { continue }
      let runFont = value as! CTFont

      let count = CTRunGetGlyphCount(run)
      var glyphs = [CGGlyph](repeating: 0, count: count)
      var positions = [CGPoint](repeating: .zero, count: count)
      CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
      CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)

      for (glyph, position) in zip(glyphs, positions) {
        guard let outline = CTFontCreatePathForGlyph(runFont, glyph, nil) else { continue }
        // Core Text draws up from the baseline, SwiftUI down from the top.
        addPath(
          Path(outline),
          transform: CGAffineTransform(translationX: position.x, y: font.ascender).scaledBy(x: 1, y: -1)
        )
      }
    }
  }

  /// The shape with its counters closed: the holes in an "o" or an "8" filled in, so an outline
  /// drawn round it runs round the outside only and the holes come out solid, as a sticker's do.
  ///
  /// A glyph's counters run the opposite way round to its outer edge, so they are the contours
  /// whose signed area has the other sign from the largest one. The areas are worked from the
  /// contours' points, control points included, which is plenty to tell which way each one runs.
  var withoutCounters: Path {
    var contours: [(path: Path, points: [CGPoint])] = []
    var path = Path()
    var points: [CGPoint] = []

    forEach { element in
      switch element {
      case let .move(to: point):
        if path.isEmpty == false { contours.append((path, points)) }
        path = Path()
        path.move(to: point)
        points = [point]
      case let .line(to: point):
        path.addLine(to: point)
        points.append(point)
      case let .quadCurve(to: point, control: control):
        path.addQuadCurve(to: point, control: control)
        points += [control, point]
      case let .curve(to: point, control1: first, control2: second):
        path.addCurve(to: point, control1: first, control2: second)
        points += [first, second, point]
      case .closeSubpath:
        path.closeSubpath()
      }
    }
    if path.isEmpty == false { contours.append((path, points)) }

    let areas = contours.map { contour in
      zip(contour.points, contour.points.dropFirst() + contour.points.prefix(1))
        .reduce(0) { $0 + ($1.0.x * $1.1.y - $1.1.x * $1.0.y) } / 2
    }
    guard let outer = areas.max(by: { abs($0) < abs($1) }) else { return self }

    var filled = Path()
    for (contour, area) in zip(contours, areas) where (area > 0) == (outer > 0) {
      filled.addPath(contour.path)
    }
    return filled
  }
}
