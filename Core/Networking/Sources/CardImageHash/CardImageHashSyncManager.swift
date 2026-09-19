import Foundation
@preconcurrency import Vision

public final actor CardImageHashSyncManager: CardImageHashSyncManagable {
  public typealias DataLoader = @Sendable (URL) async throws -> (Data, URLResponse)

  /// Loaded once per app session; later syncs only check the manifest.
  private var index: CardFeaturePrintIndex?
  /// Opening the scanner again while a sync runs joins it instead of starting another.
  private var runningSync: Task<Void, Never>?

  public var isReady = false
  public var syncStatus = "Initializing..." {
    didSet {
      print(syncStatus)
    }
  }
  public var isDownloading = false

  private let baseURL: String
  private let defaults: UserDefaults
  private let loadData: DataLoader
  private let documentsDirectory: URL

  private var indexURL: URL {
    documentsDirectory.appendingPathComponent("MTG_Hashes.index")
  }

  /// Where builds before `CardFeaturePrintIndex` kept the database and its manifest.
  private var legacyDatabaseURL: URL {
    documentsDirectory.appendingPathComponent("MTG_Hashes_Compressed.lzfse")
  }

  private var legacyManifestURL: URL {
    documentsDirectory.appendingPathComponent("manifest.json")
  }

  func generateFeaturePrint(from cgImage: CGImage) throws -> VNFeaturePrintObservation? {
    let request = VNGenerateImageFeaturePrintRequest()

    // Revision2 is the floor everywhere at our deployment target, and the
    // stored database is built with it, so there is nothing to branch on.
    request.revision = VNGenerateImageFeaturePrintRequestRevision2
    request.imageCropAndScaleOption = .scaleFill

    try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
    return request.results?.first as? VNFeaturePrintObservation
  }

  public init(
    baseURL: String = "https://missingems.github.io/MTGImageHash",
    defaults: UserDefaults = .standard,
    documentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
    loadData: @escaping DataLoader = { try await URLSession.shared.data(from: $0) }
  ) {
    self.baseURL = baseURL
    self.defaults = defaults
    self.documentsDirectory = documentsDirectory
    self.loadData = loadData
  }

  public func sync() async {
    if let runningSync {
      return await runningSync.value
    }
    let sync = Task {
      await loadLocalIndex()
      await syncFromGitHub()
    }
    runningSync = sync
    await sync.value
    runningSync = nil
  }

  public func findBestMatches(for image: CGImage) async -> [MatchResult] {
#if targetEnvironment(simulator)
    return [MatchResult(id: "57950af0-92d8-467e-9124-2206c84228c8", distance: 0)]
#else
    guard let index, let targetObservation = try? generateFeaturePrint(from: image) else {
      return []
    }

    let elementCount = targetObservation.elementCount
    let targetVector = [Float](unsafeUninitializedCapacity: elementCount) { buffer, initializedCount in
      _ = targetObservation.data.copyBytes(to: buffer)
      initializedCount = elementCount
    }
    return await index.bestMatches(for: targetVector)
#endif
  }

  // MARK: - Loading & Sync

  /// Maps the stored index. Only the first run after installing, or after
  /// updating from a build that kept the old format, has to convert a database:
  /// the one the old format left in the documents directory, or else the bundled one.
  private func loadLocalIndex() async {
    guard index == nil else { return }

    if let stored = try? CardFeaturePrintIndex(contentsOf: indexURL) {
      index = stored
      isReady = true
      syncStatus = "Loaded \(stored.ids.count) cards locally."
      // Stored without the search's shortlist (building it failed, or an older
      // build wrote it): searches check every face until it is rebuilt here.
      if stored.shortlistDimension == 0, !stored.ids.isEmpty {
        try? await store(stored)
      }
      return
    }

    let hasLegacyDatabase = FileManager.default.fileExists(atPath: legacyDatabaseURL.path)
    guard let databaseURL = hasLegacyDatabase
      ? legacyDatabaseURL
      : Bundle.module.url(forResource: "MTG_Hashes_Compressed", withExtension: "lzfse")
    else {
      syncStatus = "Error: Missing MTG_Hashes_Compressed.lzfse in module resources."
      return
    }
    // Ship MTG_Hashes_Manifest.json (the server's manifest.json for the same
    // master) alongside the bundled database, and fresh installs only fetch
    // patches. Without it the first sync downloads the full master.
    let manifestURL = hasLegacyDatabase
      ? legacyManifestURL
      : Bundle.module.url(forResource: "MTG_Hashes_Manifest", withExtension: "json")

    syncStatus = "First launch: Unpacking database..."
    do {
      var converted = try await CardFeaturePrintIndex.decoding(Data(contentsOf: databaseURL, options: .alwaysMapped))
      if let manifestURL,
         let manifestData = try? Data(contentsOf: manifestURL),
         let manifest = try? JSONDecoder().decode(CardHashDatabaseManifest.self, from: manifestData) {
        converted.masterVersion = manifest.masterVersion
        converted.latestPatch = manifest.latestPatch
      }
      try await store(converted)
      syncStatus = "Loaded \(converted.ids.count) cards locally."
    } catch {
      syncStatus = "Failed to load local cache. Corrupted file."
    }
  }

  private func syncFromGitHub() async {
    guard let baseURL = URL(string: baseURL) else { return }

    self.isDownloading = true
    defer { self.isDownloading = false }

    do {
      let remoteManifestData = try await download(baseURL.appendingPathComponent("manifest.json"), or: .manifestFetchFailed)
      let remoteManifest = try JSONDecoder().decode(CardHashDatabaseManifest.self, from: remoteManifestData)

      // -1 means "download the full master": no local index, one whose master is
      // unknown (the bundled database), or one from a different master.
      var localPatchLevel = -1
      if let index, index.masterVersion == remoteManifest.masterVersion {
        localPatchLevel = index.latestPatch
      }

      guard remoteManifest.latestPatch > localPatchLevel else {
        self.syncStatus = "Database is up to date."
        return
      }

      var updated: CardFeaturePrintIndex
      if let index, localPatchLevel != -1, remoteManifest.latestPatch - localPatchLevel <= 20 {
        self.syncStatus = "Downloading \(remoteManifest.latestPatch - localPatchLevel) update(s)..."
        let patchURLs = (localPatchLevel + 1...remoteManifest.latestPatch).map {
          baseURL.appendingPathComponent("patch_\($0).lzfse")
        }
        updated = try await CardFeaturePrintIndex.merging([index] + downloadAndDecode(patchURLs))
      } else {
        self.syncStatus = "Downloading database..."
        guard remoteManifest.masterChunks > 0 else { throw SyncError.databaseFetchFailed }
        let chunkURLs = (0..<remoteManifest.masterChunks).map {
          baseURL.appendingPathComponent("MTG_Hashes_Master_\($0).lzfse")
        }
        updated = try await CardFeaturePrintIndex.merging(downloadAndDecode(chunkURLs))
        guard !updated.ids.isEmpty else { throw SyncError.decodeFailed }
      }
      updated.masterVersion = remoteManifest.masterVersion
      updated.latestPatch = remoteManifest.latestPatch

      try await store(updated)
      self.syncStatus = "Up to date (\(updated.ids.count) cards)."
    } catch {
      // The stored index is untouched on any failure; the next sync retries.
      self.syncStatus = "Failed to sync: \(error.localizedDescription)"
    }
  }

  /// Builds the search's compressed copy, writes the index and maps it back,
  /// which releases the in-memory copy of the vectors. Files the old format
  /// kept are superseded once this succeeds.
  private func store(_ updated: CardFeaturePrintIndex) async throws {
    index = try await Self.written(updated, to: indexURL)
    isReady = true
    try? FileManager.default.removeItem(at: legacyDatabaseURL)
    try? FileManager.default.removeItem(at: legacyManifestURL)
  }

  @concurrent
  private static func written(_ index: CardFeaturePrintIndex, to url: URL) async throws -> CardFeaturePrintIndex {
    try await index.compressedForSearch().write(to: url)
    return try CardFeaturePrintIndex(contentsOf: url)
  }

  // MARK: - Download Helpers

  private nonisolated func download(_ url: URL, or failure: SyncError) async throws -> Data {
    let (data, response) = try await loadData(url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw failure }
    return data
  }

  /// Downloads the files at once and decodes each as it arrives, one at a time:
  /// decoding already spreads across cores, and a chunk in flight holds ~200 MB.
  /// Returned in the order given. Every file must arrive: a missing master chunk
  /// or patch fails the whole sync, so nothing partial is stored and the patch
  /// level never claims a skipped patch.
  private nonisolated func downloadAndDecode(_ urls: [URL]) async throws -> [CardFeaturePrintIndex] {
    try await withThrowingTaskGroup(of: (Int, Data).self) { group in
      for (position, url) in urls.enumerated() {
        group.addTask { (position, try await self.download(url, or: .databaseFetchFailed)) }
      }
      var decoded: [(Int, CardFeaturePrintIndex)] = []
      for try await (position, data) in group {
        decoded.append((position, try await CardFeaturePrintIndex.decoding(data)))
      }
      return decoded.sorted { $0.0 < $1.0 }.map(\.1)
    }
  }
}
