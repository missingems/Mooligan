import ComposableArchitecture
import Foundation
import ScryfallKit

public struct CachedGameSetRequestClient: GameSetRequestClient {
  @Dependency(\.remoteGameSetRequestClient) private var remote
  @Dependency(\.date.now) private var now

  private let store = CardStore()

  public init() {}

  public func getSets(
    queryType: GameSetQueryType
  ) async throws -> ([ScryfallClient.SetsSection], [MTGSet]) {
    try await getSets(queryType: queryType, policy: .cacheFirst)
  }

  public func getSets(
    queryType: GameSetQueryType,
    policy: CachePolicy
  ) async throws -> ([ScryfallClient.SetsSection], [MTGSet]) {
    switch queryType {
    case .all:
      let sets = try await allSets(policy: policy)
      return (ScryfallClient.sections(from: sets), sets)

    case let .name(name, existingSets):
      let sets = existingSets.isEmpty ? try await allSets(policy: policy) : existingSets
      return (ScryfallClient.sections(from: sets, matching: name), sets)
    }
  }

  private func allSets(policy: CachePolicy) async throws -> [MTGSet] {
    let cached = (try? await store.allSets()) ?? []

    if policy == .cacheFirst, cached.isEmpty == false, await isFresh() {
      return cached
    }

    do {
      let (_, sets) = try await remote.getSets(queryType: .all)
      _ = try? await store.upsert(sets: sets)
      return sets
    } catch {
      guard cached.isEmpty == false else {
        throw error
      }

      return cached
    }
  }

  private func isFresh() async -> Bool {
    guard let fetchedAt = try? await store.setsFetchedAt() ?? nil else {
      return false
    }

    return BulkRefreshSchedule.isCheckDue(lastCheckedAt: fetchedAt, now: now) == false
  }
}

public enum RemoteGameSetRequestClientKey: DependencyKey {
  public static let liveValue: any GameSetRequestClient = ScryfallClient()
#if DEBUG
  public static let previewValue: any GameSetRequestClient = MockGameSetRequestClient()
  public static let testValue: any GameSetRequestClient = MockGameSetRequestClient()
#endif
}

public extension DependencyValues {
  var remoteGameSetRequestClient: any GameSetRequestClient {
    get { self[RemoteGameSetRequestClientKey.self] }
    set { self[RemoteGameSetRequestClientKey.self] = newValue }
  }
}
