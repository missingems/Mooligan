@testable import Networking
import Foundation
import Testing

struct TextElementParserTests {
  @Test func whenParsingEmptyText_shouldReturnNoElements() {
    #expect(TextElementParser.parse("").isEmpty)
  }

  @Test func whenParsingPlainText_shouldReturnASingleElement() {
    // Runs of unstyled characters belong in one element. Emitting one element per
    // character turns a card's rules text into hundreds of `Text` views downstream.
    let elements = TextElementParser.parse("Draw two cards.")

    #expect(elements == [.text("Draw two cards.", isItalic: false, isKeyword: false)])
  }

  @Test func whenParsingLongPlainText_shouldStillReturnASingleElement() {
    let text = String(repeating: "When this creature enters, draw a card. ", count: 5)
    let elements = TextElementParser.parse(text)

    #expect(elements.count == 1)
  }

  @Test func whenParsingAToken_shouldReturnATokenElement() {
    #expect(TextElementParser.parse("{T}") == [.token("T")])
  }

  @Test func whenParsingHybridToken_shouldKeepTheSeparator() {
    #expect(TextElementParser.parse("{2/W}") == [.token("2/W")])
  }

  @Test func whenParsingTextAroundAToken_shouldSplitOnTheToken() {
    let elements = TextElementParser.parse("Add {G} now")

    #expect(
      elements == [
        .text("Add ", isItalic: false, isKeyword: false),
        .token("G"),
        .text(" now", isItalic: false, isKeyword: false),
      ]
    )
  }

  @Test func whenParsingParentheses_shouldMarkTheContentsItalic() {
    let elements = TextElementParser.parse("(Reminder)")

    #expect(
      elements == [
        .text("(", isItalic: true, isKeyword: false),
        .text("Reminder", isItalic: true, isKeyword: false),
        .text(")", isItalic: true, isKeyword: false),
      ]
    )
  }

  @Test func whenParsingAfterParentheses_shouldStopBeingItalic() {
    let elements = TextElementParser.parse("(a) b")

    #expect(elements.last == .text(" b", isItalic: false, isKeyword: false))
  }

  @Test func whenParsingAngleBrackets_shouldMarkTheContentsAsKeyword() {
    let elements = TextElementParser.parse("<Flying>")

    #expect(elements == [.text("Flying", isItalic: false, isKeyword: true)])
  }

  @Test func whenParsingTextAroundAKeyword_shouldSplitOnTheKeyword() {
    let elements = TextElementParser.parse("has <Flying> and")

    #expect(
      elements == [
        .text("has ", isItalic: false, isKeyword: false),
        .text("Flying", isItalic: false, isKeyword: true),
        .text(" and", isItalic: false, isKeyword: false),
      ]
    )
  }

  @Test func whenParsingMixedContent_shouldPreserveEveryCharacter() {
    let text = "Flying, vigilance\n{T}: Add (W). Has <haste> and {G} too."
    let elements = TextElementParser.parse(text)

    let reconstructed = elements.reduce(into: "") { result, element in
      switch element {
      case let .text(value, _, _): result += value
      case let .token(value): result += "{\(value)}"
      }
    }

    // Angle brackets are markup rather than content, so they are the only thing dropped.
    #expect(reconstructed == text.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: ""))
  }

  @Test func whenParsingMixedContent_shouldNotEmitOneElementPerCharacter() {
    let text = "Flying, vigilance\n{T}: Add (W). Has <haste> and {G} too."
    let elements = TextElementParser.parse(text)

    #expect(elements.count < text.count / 4)
  }

  @Test func whenParsingAnUnclosedToken_shouldNotEmitAToken() {
    let elements = TextElementParser.parse("Add {G")

    #expect(elements == [.text("Add ", isItalic: false, isKeyword: false)])
  }
}
