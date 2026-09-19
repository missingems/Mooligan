@testable import Networking
import Foundation
import Testing

struct CardFeaturePrintIndexTests {
  @Test func bestMatches_shouldReturnTheNearestFacesWithinTheThreshold() async throws {
    let dictionary: [String: Data] = [
      "exact": try FeaturePrintArchiveFixture.archive([1, 0, 0, 0]),
      "near": try FeaturePrintArchiveFixture.archive([0.5, 0, 0, 0]),
      "far": try FeaturePrintArchiveFixture.archive([0, 0, 0, 1]),
    ]
    let plist = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
    let index = try await CardFeaturePrintIndex.decoding(plist)
    let expected = [MatchResult(id: "exact", distance: 0), MatchResult(id: "near", distance: 0.25)]

    #expect(await index.bestMatches(for: [1, 0, 0, 0]) == expected)
    #expect(await index.compressedForSearch().bestMatches(for: [1, 0, 0, 0]) == expected)
  }

  @Test func bestMatches_whenShortlistingFromTheStoredCompressedCopy_shouldFindTheFace() async throws {
    // 1,000 faces of 256 numbers that vary along 10 directions, so the 128
    // compressed directions capture them and the 200-face shortlist is a fifth of them.
    let dimension = 256, faceCount = 1_000
    let basis = (0..<10).map { k in (0..<dimension).map { Float(sin(Double($0 * (k + 1)) * 0.37)) } }
    let faces = (0..<faceCount).map { face in
      (0..<dimension).map { j in
        (0..<10).reduce(Float(0)) { sum, k in sum + Float(cos(Double(face * 31 + k * 17))) * basis[k][j] }
      }.map { Float(Float16($0)) }
    }
    let vectors = faces.flatMap { $0.map { Float16($0) } }.withUnsafeBytes { Data($0) }
    let index = await CardFeaturePrintIndex(ids: faces.indices.map(String.init), dimension: dimension, vectors: vectors)
      .compressedForSearch()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try index.write(to: url)

    let stored = try CardFeaturePrintIndex(contentsOf: url)

    #expect(stored.shortlistDimension == 128)
    for face in [0, 123, 999] {
      #expect(await stored.bestMatches(for: faces[face]).first == MatchResult(id: String(face), distance: 0))
    }
  }

  @Test func whenAVectorIsNotFinite_shouldLeaveItOut() async throws {
    let dictionary: [String: Data] = [
      "finite": try FeaturePrintArchiveFixture.archive([1, 0, 0, 0]),
      "nan": try FeaturePrintArchiveFixture.archive([.nan, 0, 0, 0]),
      "infinite": try FeaturePrintArchiveFixture.archive([.infinity, 0, 0, 0]),
    ]
    let plist = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)

    let index = try await CardFeaturePrintIndex.decoding(plist)

    #expect(index.ids == ["finite"])
    #expect(await index.compressedForSearch().shortlistDimension == 4)
  }

  @Test(arguments: [
    // Not an index at all, with sizes that would overflow if trusted.
    [UInt32](repeating: 0xFFFF_FFFF, count: 8),
    // The right magic and version, with the same sizes.
    [0x5647_544D, 1, 0xFFFF_FFFF, 0xFFFF_FFFF, 0, 0xFFFF_FFFF, 0xFFFF_FFFF, 0xFFFF_FFFF],
  ])
  func whenTheHeaderIsCorrupt_shouldThrowRatherThanCrash(header: [UInt32]) throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try header.map(\.littleEndian).withUnsafeBytes { Data($0) }.write(to: url)

    #expect(throws: SyncError.self) { try CardFeaturePrintIndex(contentsOf: url) }
  }
}
