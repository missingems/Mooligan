import Accelerate
import Foundation
@preconcurrency import Vision

/// The card-recognition database as one flat file the scanner memory-maps.
///
/// The server format (LZFSE binary plists of archived `VNFeaturePrintObservation`s)
/// takes seconds and gigabytes to decode, so it is decoded once, when downloaded,
/// and stored like this:
///
/// - a 32-byte header of little-endian 32-bit fields: `"MTGV"`, format version 1, face count,
///   vector dimension, patch level, master version byte length, ids byte length,
///   shortlist dimension;
/// - `count × dimension` Float16 vectors, row by row, straight after the header so
///   every mapped row is aligned;
/// - `shortlistDimension × dimension` Float32s: the projection (see `compressedForSearch()`);
/// - `count × shortlistDimension` Float16s: every vector, projected;
/// - the master version, UTF-8;
/// - the face ids, UTF-8, joined by newlines.
///
/// Vectors and projection are in the device's byte order, little-endian on
/// every Apple device. Feature prints are computed in half precision on the Neural Engine, and the
/// server rounds its own to match, so Float16 loses nothing and halves the file.
struct CardFeaturePrintIndex: Sendable {
  /// The server master this index holds, or nil when unknown (the bundled
  /// database has no manifest), which makes the next sync download the master.
  var masterVersion: String?
  /// Patches applied on top of `masterVersion`; -1 when that is unknown.
  var latestPatch: Int
  let ids: [String]
  let dimension: Int
  /// `ids.count × dimension` Float16 bit patterns, mapped from disk once stored.
  let vectors: Data
  /// The directions the search shortlists along, one row of `dimension` each.
  /// Empty until `compressedForSearch()`.
  let projection: [Float]
  /// `ids.count × shortlistDimension` Float16 bit patterns: `vectors` projected.
  let shortlistVectors: Data

  var shortlistDimension: Int { dimension == 0 ? 0 : projection.count / dimension }

  init(
    masterVersion: String? = nil,
    latestPatch: Int = -1,
    ids: [String],
    dimension: Int,
    vectors: Data,
    projection: [Float] = [],
    shortlistVectors: Data = Data()
  ) {
    self.masterVersion = masterVersion
    self.latestPatch = latestPatch
    self.ids = ids
    self.dimension = dimension
    self.vectors = vectors
    self.projection = projection
    self.shortlistVectors = shortlistVectors
  }
}

// MARK: - File

extension CardFeaturePrintIndex {
  /// Maps the file rather than reading it: the vectors stay clean, file-backed
  /// memory the system can page out, and loading costs only splitting the ids.
  init(contentsOf url: URL) throws {
    let file = try Data(contentsOf: url, options: .alwaysMapped)
    guard file.count >= 32 else { throw SyncError.decodeFailed }
    let header = file.withUnsafeBytes { bytes in
      (0..<8).map { UInt32(littleEndian: bytes.loadUnaligned(fromByteOffset: $0 * 4, as: UInt32.self)) }
    }
    // Checked before any arithmetic on them: sizes from a corrupt header could
    // overflow and crash every launch, since the same file loads each time.
    // No field of a real file exceeds its length (the patch level is signed).
    guard header[0] == 0x5647_544D, header[1] == 1,
          [2, 3, 5, 6, 7].allSatisfy({ Int(header[$0]) <= file.count }) else {
      throw SyncError.decodeFailed
    }
    let count = Int(header[2]), dimension = Int(header[3]), shortlistDimension = Int(header[7])
    let vectorsEnd = 32 + count * dimension * 2
    let projectionEnd = vectorsEnd + shortlistDimension * dimension * 4
    let shortlistEnd = projectionEnd + count * shortlistDimension * 2
    let versionEnd = shortlistEnd + Int(header[5])
    guard file.count == versionEnd + Int(header[6]) else { throw SyncError.decodeFailed }

    let projection = file[vectorsEnd..<projectionEnd].withUnsafeBytes { bytes in
      (0..<shortlistDimension * dimension).map { bytes.loadUnaligned(fromByteOffset: $0 * 4, as: Float.self) }
    }
    let masterVersion = String(decoding: file[shortlistEnd..<versionEnd], as: UTF8.self)
    let ids = count == 0 ? [] : file[versionEnd...].split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: false)
      .map { String(decoding: $0, as: UTF8.self) }
    guard ids.count == count else { throw SyncError.decodeFailed }

    self.init(
      masterVersion: masterVersion.isEmpty ? nil : masterVersion,
      latestPatch: Int(Int32(bitPattern: header[4])),
      ids: ids,
      dimension: dimension,
      // Slices share the mapping; `subdata` would copy them into memory.
      vectors: file[32..<vectorsEnd],
      projection: projection,
      shortlistVectors: file[projectionEnd..<shortlistEnd]
    )
  }

  /// Writes through `<url>.partial` and renames it over `url`, so a crash
  /// leaves the previous index intact, and the next write reuses the partial
  /// file rather than leaving another behind. Excluded from backup: it can be
  /// downloaded again.
  func write(to url: URL) throws {
    let masterVersion = Data((masterVersion ?? "").utf8)
    let ids = Data(ids.joined(separator: "\n").utf8)
    let fields: [UInt32] = [
      0x5647_544D, 1, UInt32(self.ids.count), UInt32(dimension), UInt32(bitPattern: Int32(latestPatch)),
      UInt32(masterVersion.count), UInt32(ids.count), UInt32(shortlistDimension),
    ]
    let header = fields.map(\.littleEndian).withUnsafeBytes { Data($0) }
    let projection = projection.withUnsafeBytes { Data($0) }

    var temporaryURL = url.appendingPathExtension("partial")
    guard FileManager.default.createFile(atPath: temporaryURL.path, contents: nil) else {
      throw CocoaError(.fileWriteUnknown)
    }
    // Set before writing, and carried over by the rename.
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true
    try? temporaryURL.setResourceValues(resourceValues)
    do {
      let handle = try FileHandle(forWritingTo: temporaryURL)
      do {
        for part in [header, vectors, projection, shortlistVectors, masterVersion, ids] {
          try handle.write(contentsOf: part)
        }
        try handle.synchronize()
      } catch {
        try? handle.close()
        throw error
      }
      try handle.close()
      guard rename(temporaryURL.path, url.path) == 0 else { throw CocoaError(.fileWriteUnknown) }
    } catch {
      try? FileManager.default.removeItem(at: temporaryURL)
      throw error
    }
  }
}

// MARK: - Merging

extension CardFeaturePrintIndex {
  /// Combines indexes in order; a face in a later index replaces the same face
  /// in an earlier one, as a patch does. The result has no master version and
  /// no shortlist.
  @concurrent
  static func merging(_ indexes: [CardFeaturePrintIndex]) async throws -> CardFeaturePrintIndex {
    let indexes = indexes.filter { !$0.ids.isEmpty }
    guard let dimension = indexes.first?.dimension else {
      return CardFeaturePrintIndex(ids: [], dimension: 0, vectors: Data())
    }
    guard indexes.allSatisfy({ $0.dimension == dimension }) else { throw SyncError.decodeFailed }

    var rowForID: [String: Int] = [:]
    var ids: [String] = []
    // For every output row, which index and row its vector comes from.
    var sources: [(index: Int, row: Int)] = []
    for (indexPosition, index) in indexes.enumerated() {
      for (row, id) in index.ids.enumerated() {
        if let existing = rowForID[id] {
          sources[existing] = (indexPosition, row)
        } else {
          rowForID[id] = ids.count
          ids.append(id)
          sources.append((indexPosition, row))
        }
      }
    }

    let rowBytes = dimension * 2
    var vectors = Data(count: ids.count * rowBytes)
    vectors.withUnsafeMutableBytes { output in
      for (indexPosition, index) in indexes.enumerated() {
        index.vectors.withUnsafeBytes { input in
          for (row, source) in sources.enumerated() where source.index == indexPosition {
            UnsafeMutableRawBufferPointer(rebasing: output[row * rowBytes..<(row + 1) * rowBytes])
              .copyMemory(from: UnsafeRawBufferPointer(rebasing: input[source.row * rowBytes..<(source.row + 1) * rowBytes]))
          }
        }
      }
    }
    return CardFeaturePrintIndex(ids: ids, dimension: dimension, vectors: vectors)
  }
}

// MARK: - Server format

extension CardFeaturePrintIndex {
  /// Decodes a master chunk or patch: an LZFSE binary plist of
  /// `[faceId: NSKeyedArchiver(VNFeaturePrintObservation)]`. Unarchiving is the
  /// slow part, so it is split across cores.
  @concurrent
  static func decoding(_ data: Data) async throws -> CardFeaturePrintIndex {
    let entries = try archivedEntries(data)
    let sliceSize = max(1_000, entries.count / ProcessInfo.processInfo.activeProcessorCount + 1)
    let slices = await withTaskGroup(of: (Int, CardFeaturePrintIndex).self) { group in
      for start in stride(from: 0, to: entries.count, by: sliceSize) {
        let slice = entries[start..<min(start + sliceSize, entries.count)]
        group.addTask { (start, Self.unarchived(slice)) }
      }
      var slices: [(Int, CardFeaturePrintIndex)] = []
      for await slice in group { slices.append(slice) }
      return slices.sorted { $0.0 < $1.0 }.map(\.1)
    }
    return try await merging(slices)
  }

  /// Frees the decompressed plist (~55 MB a chunk) before unarchiving starts.
  /// The pool matters as much as the function boundary: anything these
  /// Foundation calls autorelease would otherwise live until the thread drains.
  private static func archivedEntries(_ data: Data) throws -> [(key: String, value: Data)] {
    try autoreleasepool {
      let decompressed = (try? (data as NSData).decompressed(using: .lzfse) as Data) ?? data
      guard let dictionary = try PropertyListSerialization.propertyList(
        from: decompressed,
        options: [],
        format: nil
      ) as? [String: Data] else {
        throw SyncError.decodeFailed
      }
      return Array(dictionary)
    }
  }

  private static func unarchived(_ entries: ArraySlice<(key: String, value: Data)>) -> CardFeaturePrintIndex {
    var ids: [String] = []
    var floats: [Float] = []
    var dimension = 0
    for (id, archive) in entries {
      // Each unarchived observation is autoreleased; without a pool per entry
      // they would all stay alive until the slice finishes.
      autoreleasepool {
        guard let observation = try? NSKeyedUnarchiver.unarchivedObject(
          ofClass: VNFeaturePrintObservation.self,
          from: archive
        ), observation.elementType == .float else { return }
        if dimension == 0 {
          dimension = observation.elementCount
          floats.reserveCapacity(entries.count * dimension)
        }
        guard observation.elementCount == dimension else { return }
        let vector = [Float](unsafeUninitializedCapacity: dimension) { buffer, initializedCount in
          _ = observation.data.copyBytes(to: buffer)
          initializedCount = dimension
        }
        // A NaN or infinity never matches, and in the sample it would stop the
        // search's shortlist from being built at all.
        guard vector.allSatisfy(\.isFinite) else { return }
        ids.append(id)
        floats.append(contentsOf: vector)
      }
    }

    var vectors = Data(count: floats.count * 2)
    if !floats.isEmpty {
      vectors.withUnsafeMutableBytes { halves in
        narrow(floats, rows: ids.count, width: dimension, into: halves.baseAddress!)
      }
    }
    return CardFeaturePrintIndex(ids: ids, dimension: dimension, vectors: vectors)
  }
}

// MARK: - Search

extension CardFeaturePrintIndex {
  /// Adds the compressed copy the search shortlists from: the 128 directions
  /// the vectors vary along most (principal components, found from ~8,000 of
  /// them), and every vector projected onto those, 27 MB for 107k faces.
  ///
  /// Measured on the real database with camera-like frames made from real card
  /// images, a 200-face shortlist from this copy keeps 99–100% of the matches a
  /// scan of the full vectors finds; Float16, and the sample instead of every
  /// vector, lose nothing.
  @concurrent
  func compressedForSearch() async -> CardFeaturePrintIndex {
    let count = ids.count, dimension = dimension
    guard count > 0 else { return self }
    let shortlistDimension = min(128, dimension)

    let sampleRows = Array(stride(from: 0, to: count, by: max(1, count / 8_192)))
    var sample = [Float](repeating: 0, count: sampleRows.count * dimension)
    vectors.withUnsafeBytes { halves in
      sample.withUnsafeMutableBufferPointer { sample in
        for (position, row) in sampleRows.enumerated() {
          Self.widen(halves, rows: row..<row + 1, width: dimension, into: sample.baseAddress! + position * dimension)
        }
      }
    }

    // Covariance of the sample, then its eigenvectors, which LAPACK returns one
    // per contiguous run of `dimension`, by ascending eigenvalue.
    var mean = [Float](repeating: 0, count: dimension)
    sample.withUnsafeBufferPointer { sample in
      for column in 0..<dimension {
        vDSP_meanv(sample.baseAddress! + column, vDSP_Stride(dimension), &mean[column], vDSP_Length(sampleRows.count))
      }
    }
    var covariance = [Float](repeating: 0, count: dimension * dimension)
    cblas_sgemm(
      CblasRowMajor, CblasTrans, CblasNoTrans, __LAPACK_int(dimension), __LAPACK_int(dimension), __LAPACK_int(sampleRows.count),
      1 / Float(sampleRows.count), sample, __LAPACK_int(dimension), sample, __LAPACK_int(dimension), 0, &covariance, __LAPACK_int(dimension)
    )
    cblas_sger(CblasRowMajor, __LAPACK_int(dimension), __LAPACK_int(dimension), -1, mean, 1, mean, 1, &covariance, __LAPACK_int(dimension))

    var eigenvalues = [Float](repeating: 0, count: dimension)
    var order = __LAPACK_int(dimension), leadingDimension = __LAPACK_int(dimension)
    var workSize = __LAPACK_int(-1), optimalWorkSize: Float = 0, info = __LAPACK_int(0)
    ssyev_("V", "U", &order, &covariance, &leadingDimension, &eigenvalues, &optimalWorkSize, &workSize, &info)
    workSize = __LAPACK_int(optimalWorkSize)
    var work = [Float](repeating: 0, count: Int(workSize))
    ssyev_("V", "U", &order, &covariance, &leadingDimension, &eigenvalues, &work, &workSize, &info)
    // Without a shortlist the search checks every face: slow, but still right.
    guard info == 0 else { return self }
    let projection = Array(covariance[(dimension - shortlistDimension) * dimension..<dimension * dimension])

    // Project every vector, 4,096 rows at a time, so no full Float32 copy exists.
    var shortlistVectors = Data(count: count * shortlistDimension * 2)
    var block = [Float](repeating: 0, count: 4_096 * dimension)
    var projectedBlock = [Float](repeating: 0, count: 4_096 * shortlistDimension)
    vectors.withUnsafeBytes { halves in
      shortlistVectors.withUnsafeMutableBytes { output in
        for start in stride(from: 0, to: count, by: 4_096) {
          let rows = start..<min(start + 4_096, count)
          block.withUnsafeMutableBufferPointer { Self.widen(halves, rows: rows, width: dimension, into: $0.baseAddress!) }
          cblas_sgemm(
            CblasRowMajor, CblasNoTrans, CblasTrans, __LAPACK_int(rows.count), __LAPACK_int(shortlistDimension), __LAPACK_int(dimension),
            1, block, __LAPACK_int(dimension), projection, __LAPACK_int(dimension), 0, &projectedBlock, __LAPACK_int(shortlistDimension)
          )
          Self.narrow(projectedBlock, rows: rows.count, width: shortlistDimension, into: output.baseAddress! + start * shortlistDimension * 2)
        }
      }
    }

    return CardFeaturePrintIndex(
      masterVersion: masterVersion,
      latestPatch: latestPatch,
      ids: ids,
      dimension: dimension,
      vectors: vectors,
      projection: projection,
      shortlistVectors: shortlistVectors
    )
  }

  /// The closest faces to `target`, nearest first, by squared Euclidean distance.
  /// Only distances below 1 count as candidates.
  ///
  /// Scans the compressed copy for the 200 likeliest faces, then measures only
  /// those against the full vectors: each search reads 27 MB of the ~200 MB
  /// file, plus 200 scattered rows, rather than all of it.
  @concurrent
  func bestMatches(for target: [Float], limit: Int = 5) async -> [MatchResult] {
    guard target.count == dimension, !ids.isEmpty else { return [] }

    let shortlist: [Int]
    if shortlistDimension > 0 {
      var projectedTarget = [Float](repeating: 0, count: shortlistDimension)
      cblas_sgemv(
        CblasRowMajor, CblasNoTrans, __LAPACK_int(shortlistDimension), __LAPACK_int(dimension),
        1, projection, __LAPACK_int(dimension), target, 1, 0, &projectedTarget, 1
      )
      shortlist = await Self.nearestRows(
        to: projectedTarget, in: shortlistVectors, width: shortlistDimension, count: ids.count, limit: max(200, limit)
      ).map(\.row)
    } else {
      shortlist = Array(ids.indices)
    }

    var nearest: [(row: Int, distance: Float)] = []
    var vector = [Float](repeating: 0, count: dimension)
    vectors.withUnsafeBytes { halves in
      vector.withUnsafeMutableBufferPointer { vector in
        for row in shortlist {
          Self.widen(halves, rows: row..<row + 1, width: dimension, into: vector.baseAddress!)
          var distance: Float = 0
          vDSP_distancesq(target, 1, vector.baseAddress!, 1, &distance, vDSP_Length(dimension))
          if distance < 1 { nearest.append((row, distance)) }
        }
      }
    }
    return nearest
      .sorted { $0.distance < $1.distance }
      .prefix(limit)
      .map { MatchResult(id: ids[$0.row], distance: $0.distance) }
  }

  /// The `limit` rows of a Float16 matrix nearest to `target`, nearest first,
  /// with the rows split across cores.
  private static func nearestRows(
    to target: [Float],
    in matrix: Data,
    width: Int,
    count: Int,
    limit: Int
  ) async -> [(row: Int, distance: Float)] {
    let sliceSize = max(2_000, count / ProcessInfo.processInfo.activeProcessorCount + 1)
    let candidates = await withTaskGroup(of: [(row: Int, distance: Float)].self) { group in
      for start in stride(from: 0, to: count, by: sliceSize) {
        let rows = start..<min(start + sliceSize, count)
        group.addTask { Self.nearestRows(to: target, rows: rows, in: matrix, width: width, limit: limit) }
      }
      var candidates: [(row: Int, distance: Float)] = []
      for await sliceCandidates in group { candidates += sliceCandidates }
      return candidates
    }
    return Array(candidates.sorted { $0.distance < $1.distance }.prefix(limit))
  }

  /// Widens 64 rows at a time into a small Float32 scratch buffer and measures
  /// them with vDSP. Reading half-precision rows halves the memory traffic,
  /// which is what a scan over 100k faces is bound by.
  private static func nearestRows(
    to target: [Float],
    rows: Range<Int>,
    in matrix: Data,
    width: Int,
    limit: Int
  ) -> [(row: Int, distance: Float)] {
    var nearest: [(row: Int, distance: Float)] = []
    nearest.reserveCapacity(limit + 1)
    let scratch = UnsafeMutableBufferPointer<Float>.allocate(capacity: 64 * width)
    defer { scratch.deallocate() }

    matrix.withUnsafeBytes { halves in
      var blockStart = rows.lowerBound
      while blockStart < rows.upperBound {
        let blockRows = min(64, rows.upperBound - blockStart)
        widen(halves, rows: blockStart..<blockStart + blockRows, width: width, into: scratch.baseAddress!)
        for offset in 0..<blockRows {
          var distance: Float = 0
          vDSP_distancesq(target, 1, scratch.baseAddress! + offset * width, 1, &distance, vDSP_Length(width))
          // Kept sorted, so the last one is the bar to beat.
          guard nearest.count < limit || distance < nearest[nearest.count - 1].distance else { continue }
          nearest.insert((blockStart + offset, distance), at: nearest.firstIndex { $0.distance > distance } ?? nearest.count)
          if nearest.count > limit { nearest.removeLast() }
        }
        blockStart += blockRows
      }
    }
    return nearest
  }

  /// Converts `rows` of a Float16 matrix into consecutive Float32 rows.
  private static func widen(
    _ halves: UnsafeRawBufferPointer,
    rows: Range<Int>,
    width: Int,
    into destination: UnsafeMutablePointer<Float>
  ) {
    var source = vImage_Buffer(
      data: UnsafeMutableRawPointer(mutating: halves.baseAddress! + rows.lowerBound * width * 2),
      height: vImagePixelCount(rows.count), width: vImagePixelCount(width), rowBytes: width * 2
    )
    var target = vImage_Buffer(
      data: UnsafeMutableRawPointer(destination),
      height: vImagePixelCount(rows.count), width: vImagePixelCount(width), rowBytes: width * 4
    )
    _ = vImageConvert_Planar16FtoPlanarF(&source, &target, 0)
  }

  /// Converts consecutive Float32 rows into Float16 bit patterns.
  private static func narrow(_ floats: [Float], rows: Int, width: Int, into destination: UnsafeMutableRawPointer) {
    floats.withUnsafeBufferPointer { floats in
      var source = vImage_Buffer(
        data: UnsafeMutableRawPointer(mutating: floats.baseAddress!),
        height: vImagePixelCount(rows), width: vImagePixelCount(width), rowBytes: width * 4
      )
      var target = vImage_Buffer(
        data: destination,
        height: vImagePixelCount(rows), width: vImagePixelCount(width), rowBytes: width * 2
      )
      _ = vImageConvert_PlanarFtoPlanar16F(&source, &target, 0)
    }
  }
}
