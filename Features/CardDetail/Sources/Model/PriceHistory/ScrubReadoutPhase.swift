import Foundation

/// The steps the scrub readout goes through when a scrub starts. A copy of each priced finish's
/// toolbar capsule shows over it; the copies slide onto one another into one glass; that glass balls
/// up as it flies to the foot of the needle; and, before it lands, the readout opens at the tip
/// while the ball is absorbed into the needle.
enum ScrubReadoutPhase: Int, Comparable, Sendable {
  case start
  case gathered
  case balled
  case expanded

  static func < (lhs: ScrubReadoutPhase, rhs: ScrubReadoutPhase) -> Bool { lhs.rawValue < rhs.rawValue }

  /// The proxy has left the toolbar as a ball heading for the needle's foot.
  var proxyIsBall: Bool { self >= .balled }

  /// The ball is being absorbed into the needle.
  var proxyIsAbsorbed: Bool { self == .expanded }

  /// Open at the tip of the needle, reading the scrubbed day.
  var readoutIsOpen: Bool { self == .expanded }
}
