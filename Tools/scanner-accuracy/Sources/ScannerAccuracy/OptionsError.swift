enum OptionsError: Error, CustomStringConvertible {
  case missingValue(String)
  case invalid(String)
  case unknown(String)

  var description: String {
    switch self {
    case let .missingValue(option): "\(option) needs a value"
    case let .invalid(option): "\(option) has an invalid value"
    case let .unknown(option): "unknown option \(option)"
    }
  }
}
