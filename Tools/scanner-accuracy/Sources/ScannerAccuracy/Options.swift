import Foundation

/// Command-line options; see README.md.
struct Options {
  var samples = 10
  var niches = Niche.all
  var environments = SimulatedEnvironment.allCases
  var cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("scanner-accuracy")
  var failures: URL?
  var frames: URL?
  var refresh = false

  init(arguments: some Sequence<String>) throws {
    var arguments = arguments.makeIterator()
    while let argument = arguments.next() {
      func value() throws -> String {
        guard let value = arguments.next() else { throw OptionsError.missingValue(argument) }
        return value
      }
      switch argument {
      case "--samples":
        guard let samples = Int(try value()), samples > 0 else { throw OptionsError.invalid(argument) }
        self.samples = samples
      case "--niche":
        let names = try value().split(separator: ",").map(String.init)
        niches = Niche.all.filter { names.contains($0.name) }
        guard niches.count == names.count else { throw OptionsError.invalid(argument) }
      case "--environment":
        environments = try value().split(separator: ",").map {
          guard let environment = SimulatedEnvironment(rawValue: String($0)) else { throw OptionsError.invalid(argument) }
          return environment
        }
      case "--cache":
        cache = URL(fileURLWithPath: try value())
      case "--failures":
        failures = URL(fileURLWithPath: try value())
      case "--frames":
        frames = URL(fileURLWithPath: try value())
      case "--refresh":
        refresh = true
      default:
        throw OptionsError.unknown(argument)
      }
    }
  }
}
