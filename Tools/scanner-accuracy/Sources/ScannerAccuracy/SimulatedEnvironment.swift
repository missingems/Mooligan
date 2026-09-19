/// A condition the card is photographed in; `FrameComposer` applies it.
enum SimulatedEnvironment: String, CaseIterable, Sendable {
  /// On a wooden table, in even light.
  case clean
  case warm
  case cool
  /// Low light, so darker and grainier.
  case dim
  /// A lamp's reflection on part of the card.
  case glare
  /// A foil's rainbow sheen, which the database's flat scans never show.
  case foil
  /// A glossy sleeve: a faint haze over the card, and a streak of reflection.
  case sleeve
  /// Tilted away from the lens.
  case angled
  /// Held farther away, so smaller in the frame.
  case far
  /// Out of focus.
  case blur
  /// Moving as the frame is taken.
  case motion
  /// On a dark playmat.
  case playmat
  /// On a white table, which the card's own edge barely stands out from.
  case white
}
