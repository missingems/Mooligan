/// A seeded generator, so every run composes the same frames.
struct SplitMix: RandomNumberGenerator {
  private var state: UInt64

  /// Seeded from a string with FNV-1a, which, unlike `hashValue`, is the same every run.
  init(seed: String) {
    state = seed.utf8.reduce(0xCBF2_9CE4_8422_2325) { ($0 ^ UInt64($1)) &* 0x100_0000_01B3 }
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}
