@testable import Networking
import Foundation
import Testing

struct GzipInflateStreamTests {
  private func inflateAll(_ compressed: Data, chunkSize: Int) throws -> Data {
    let stream = try GzipInflateStream()
    var output = Data()
    var offset = 0

    while offset < compressed.count {
      let end = min(offset + chunkSize, compressed.count)
      output.append(try stream.inflate(compressed.subdata(in: offset..<end)))
      offset = end
    }

    try stream.finish()
    return output
  }

  @Test func whenInflatingInOneChunk_shouldReturnTheOriginal() throws {
    let original = Data(String(repeating: "the quick brown fox. ", count: 500).utf8)

    let output = try inflateAll(try GzipFixture.compress(original), chunkSize: .max)

    #expect(output == original)
  }

  @Test(arguments: [1, 2, 3, 7, 11, 64, 512, 4096])
  func whenInflatingAtAnyChunkSize_shouldReturnTheOriginal(chunkSize: Int) throws {
    let original = Data(String(repeating: "Lightning Bolt deals 3 damage. ", count: 200).utf8)

    let output = try inflateAll(try GzipFixture.compress(original), chunkSize: chunkSize)

    #expect(output == original)
  }

  @Test func whenHeaderCarriesOptionalFields_shouldSkipThemAll() throws {
    let original = Data("{\"name\":\"Counterspell\"}".utf8)
    let compressed = try GzipFixture.compress(
      original,
      options: .init(
        filename: "default-cards.jsonl",
        comment: "scryfall bulk export",
        extraField: [0x01, 0x02, 0x03, 0x04]
      )
    )

    #expect(try inflateAll(compressed, chunkSize: 1) == original)
  }

  @Test func whenDataIsNotGzip_shouldFailFast() throws {
    let stream = try GzipInflateStream()

    #expect(throws: GzipInflateStream.Failure.notGzip) {
      _ = try stream.inflate(Data("<!doctype html><html>".utf8))
    }
  }

  @Test func whenCompressionMethodIsUnknown_shouldFailFast() throws {
    let stream = try GzipInflateStream()

    #expect(throws: GzipInflateStream.Failure.notGzip) {
      _ = try stream.inflate(Data([0x1F, 0x8B, 0x09, 0x00, 0, 0, 0, 0, 0, 0x03]))
    }
  }

  @Test func whenTheStreamIsTruncated_shouldThrowOnFinish() throws {
    let original = Data(String(repeating: "truncate me. ", count: 500).utf8)
    let compressed = try GzipFixture.compress(original)
    let stream = try GzipInflateStream()

    _ = try stream.inflate(compressed.prefix(compressed.count / 2))

    #expect(stream.isComplete == false)
    #expect(throws: GzipInflateStream.Failure.truncated) { try stream.finish() }
  }

  @Test func whenOnlyPartOfTheHeaderHasArrived_shouldWaitForMore() throws {
    let stream = try GzipInflateStream()

    #expect(try stream.inflate(Data([0x1F, 0x8B])).isEmpty)
    #expect(stream.isComplete == false)
  }

  @Test func whenInflatingPastTheEnd_shouldIgnoreTrailingBytes() throws {
    let original = Data("{\"id\":1}".utf8)
    var compressed = try GzipFixture.compress(original)
    compressed.append(contentsOf: [0xDE, 0xAD, 0xBE, 0xEF])

    #expect(try inflateAll(compressed, chunkSize: 8) == original)
  }

  @Test func whenInflatingALargePayload_shouldNotDependOnBufferCapacity() throws {
    let original = Data(String(repeating: "a", count: 512 * 1024).utf8)

    #expect(try inflateAll(try GzipFixture.compress(original), chunkSize: 1024) == original)
  }
}
