import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit

/// A set client that fails every request, as it does offline, and counts how often it was asked.
struct FailingSetsClient: GameSetRequestClient {
  let calls = LockIsolated(0)

  func getSets(queryType: GameSetQueryType) async throws -> ([ScryfallClient.SetsSection], [MTGSet]) {
    calls.withValue { $0 += 1 }
    throw URLError(.notConnectedToInternet)
  }
}
