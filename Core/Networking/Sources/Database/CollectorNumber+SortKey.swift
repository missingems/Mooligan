import Foundation

public enum CollectorNumber {
  public static func sortKey(_ collectorNumber: String) -> String {
    let width = 8
    var result = ""
    var digits = ""

    func flushDigits() {
      guard digits.isEmpty == false else { return }
      result += String(repeating: "0", count: max(0, width - digits.count)) + digits
      digits = ""
    }

    for character in collectorNumber {
      if character.isASCII, character.isNumber {
        digits.append(character)
      } else {
        flushDigits()
        result.append(character)
      }
    }

    flushDigits()
    return result
  }
}
