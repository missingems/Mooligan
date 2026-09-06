@testable import Networking
import Foundation
import Testing

struct JSONLineSplitterTests {
  private func text(_ lines: [Data]) -> [String] {
    lines.map { String(decoding: $0, as: UTF8.self) }
  }

  @Test func whenAChunkHoldsWholeLines_shouldEmitThemAll() {
    var splitter = JSONLineSplitter()

    let lines = splitter.lines(from: Data("{\"a\":1}\n{\"b\":2}\n".utf8))

    #expect(text(lines) == ["{\"a\":1}", "{\"b\":2}"])
    #expect(splitter.flush() == nil)
  }

  @Test func whenALineSpansChunks_shouldEmitItOnceComplete() {
    var splitter = JSONLineSplitter()

    #expect(splitter.lines(from: Data("{\"na".utf8)).isEmpty)
    #expect(splitter.lines(from: Data("me\":\"Bo".utf8)).isEmpty)
    let lines = splitter.lines(from: Data("lt\"}\n".utf8))

    #expect(text(lines) == ["{\"name\":\"Bolt\"}"])
  }

  @Test func whenTheStreamEndsWithoutANewline_shouldEmitTheLastLineOnFlush() {
    var splitter = JSONLineSplitter()

    let lines = splitter.lines(from: Data("{\"a\":1}\n{\"b\":2}".utf8))

    #expect(text(lines) == ["{\"a\":1}"])
    #expect(splitter.flush().map { String(decoding: $0, as: UTF8.self) } == "{\"b\":2}")
  }

  @Test func whenTheStreamHasBlankLines_shouldDropThem() {
    var splitter = JSONLineSplitter()

    let lines = splitter.lines(from: Data("{\"a\":1}\n\n\n{\"b\":2}\n".utf8))

    #expect(text(lines) == ["{\"a\":1}", "{\"b\":2}"])
  }

  @Test func whenLinesUseCRLF_shouldStripTheCarriageReturn() {
    var splitter = JSONLineSplitter()

    let lines = splitter.lines(from: Data("{\"a\":1}\r\n{\"b\":2}\r\n".utf8))

    #expect(text(lines) == ["{\"a\":1}", "{\"b\":2}"])
  }

  @Test func whenAMultiByteCharacterSpansChunks_shouldNotCorruptIt() {
    var splitter = JSONLineSplitter()
    let line = Data("{\"name\":\"Æther Vial ★\"}".utf8)
    let split = line.count / 2

    #expect(splitter.lines(from: line.prefix(split)).isEmpty)
    var rest = Data(line.suffix(from: split))
    rest.append(0x0A)
    let lines = splitter.lines(from: rest)

    #expect(text(lines) == ["{\"name\":\"Æther Vial ★\"}"])
  }

  @Test func whenFedOneByteAtATime_shouldStillRecoverEveryLine() {
    var splitter = JSONLineSplitter()
    let payload = Data("{\"a\":1}\n{\"b\":2}\n{\"c\":3}\n".utf8)
    var lines: [Data] = []

    for byte in payload {
      lines.append(contentsOf: splitter.lines(from: Data([byte])))
    }

    #expect(text(lines) == ["{\"a\":1}", "{\"b\":2}", "{\"c\":3}"])
  }

  @Test func whenNothingWasFed_shouldFlushNothing() {
    var splitter = JSONLineSplitter()

    #expect(splitter.lines(from: Data()).isEmpty)
    #expect(splitter.flush() == nil)
  }
}
