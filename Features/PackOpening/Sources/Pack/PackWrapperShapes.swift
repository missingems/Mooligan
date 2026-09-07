import SwiftUI

/// The serrated crimp a booster is heat-sealed with, along one edge of a rect.
///
/// Drawn as a filled shape covering the whole wrapper so it can be used both as
/// the wrapper outline and as a clip: the teeth bite *into* the rectangle.
struct CrimpedRectangle: Shape {
  var toothWidth: CGFloat = 7
  var toothDepth: CGFloat = 4

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let inset = rect.insetBy(dx: 0, dy: toothDepth)
    let teeth = max(2, Int((rect.width / toothWidth).rounded()))
    let step = rect.width / CGFloat(teeth)

    // Top crimp, left to right.
    path.move(to: CGPoint(x: rect.minX, y: inset.minY))
    for tooth in 0..<teeth {
      let x = rect.minX + CGFloat(tooth) * step
      path.addLine(to: CGPoint(x: x + step / 2, y: rect.minY))
      path.addLine(to: CGPoint(x: x + step, y: inset.minY))
    }

    // Right edge.
    path.addLine(to: CGPoint(x: rect.maxX, y: inset.maxY))

    // Bottom crimp, right to left.
    for tooth in 0..<teeth {
      let x = rect.maxX - CGFloat(tooth) * step
      path.addLine(to: CGPoint(x: x - step / 2, y: rect.maxY))
      path.addLine(to: CGPoint(x: x - step, y: inset.maxY))
    }

    path.closeSubpath()
    return path
  }
}

/// The jagged line a wrapper tears along.
///
/// The tear runs right to left, from the notch, following the player's thumb.
/// `progress` is how far across the pack it has travelled. Ahead of the front
/// the wrapper is still sealed, so the line runs straight along the crimp;
/// behind it the line wanders, because torn plastic does not tear straight.
/// `seed` makes each pack tear along its own path, and makes that path stable
/// across the many redraws a drag produces.
struct TearLine {
  let seed: UInt64
  let progress: CGFloat

  /// Vertical position of the tear as a fraction of the pack's height.
  let baseline: CGFloat

  /// Points across `width`, at the tear's height in a box of `size`.
  func points(in size: CGSize, stepCount: Int = 44) -> [CGPoint] {
    let y = size.height * baseline
    let front = size.width * (1 - progress)

    return (0...stepCount).map { step in
      let t = CGFloat(step) / CGFloat(stepCount)
      let x = size.width * t

      guard x >= front else {
        // Still sealed: dead straight along the crimp.
        return CGPoint(x: x, y: y)
      }

      // Torn: wander, and wander more the further it is from the front, where
      // the plastic has had time to relax.
      let distanceBehindFront = min(1, (x - front) / max(size.width * 0.25, 1))
      let amplitude = size.height * 0.022 * (0.35 + distanceBehindFront)
      let noise = TearLine.noise(seed: seed, index: step)

      return CGPoint(x: x, y: y + noise * amplitude)
    }
  }

  /// Deterministic `-1...1` value per point. SplitMix-style mixing so adjacent
  /// indices are uncorrelated and the edge looks ripped rather than wavy.
  static func noise(seed: UInt64, index: Int) -> CGFloat {
    var value = seed &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
    value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
    value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
    value = value ^ (value >> 31)

    return CGFloat(value % 2_000) / 1_000 - 1
  }
}

/// Everything above the tear line: the strip that comes away in your hand.
struct TornStripShape: Shape {
  var seed: UInt64
  var progress: CGFloat
  var baseline: CGFloat

  var animatableData: CGFloat {
    get { progress }
    set { progress = newValue }
  }

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let line = TearLine(seed: seed, progress: progress, baseline: baseline)
    let points = line.points(in: rect.size)

    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + points[points.count - 1].y))

    for point in points.reversed() {
      path.addLine(to: CGPoint(x: rect.minX + point.x, y: rect.minY + point.y))
    }

    path.closeSubpath()
    return path
  }
}

/// Everything below the tear line: the wrapper still holding the cards.
struct TornBodyShape: Shape {
  var seed: UInt64
  var progress: CGFloat
  var baseline: CGFloat

  var animatableData: CGFloat {
    get { progress }
    set { progress = newValue }
  }

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let line = TearLine(seed: seed, progress: progress, baseline: baseline)
    let points = line.points(in: rect.size)

    path.move(to: CGPoint(x: rect.minX, y: rect.minY + points[0].y))

    for point in points {
      path.addLine(to: CGPoint(x: rect.minX + point.x, y: rect.minY + point.y))
    }

    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}
