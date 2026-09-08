@testable import Networking
import Foundation
import Testing

/// Hits MTGGraphQL for real and checks the response actually maps to a chartable
/// series. Skipped unless a token is present, so it never runs on CI or on a
/// clone without credentials. Use the wrapper:
///
///     MTGGRAPHQL_TOKEN=... Core/Networking/GraphQL/verify-live.sh
///
/// Point `MTGGRAPHQL_URL` at the deployed proxy to exercise that path instead;
/// it defaults to talking to MTGJSON directly.
///
/// Each run costs one request against the 500/hour token budget.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["MTGGRAPHQL_TOKEN"] != nil))
struct PriceHistoryIntegrationTests {
  /// Phelddagrif, Alliances — the card MTGJSON uses in its own documentation.
  /// Deliberately the paper printing: the default Scryfall print (`me1`) is
  /// MTGO-only and carries no paper prices at all, so it would fail for a
  /// reason that has nothing to do with the code under test.
  private let scryfallID = "d9631cb2-d53b-4401-b53b-29d27bdefc44"

  private var endpoint: URL {
    let raw = ProcessInfo.processInfo.environment["MTGGRAPHQL_URL"]
      ?? "https://graphql.mtgjson.com/"
    return URL(string: raw)!
  }

  private func post() async throws -> (Data, HTTPURLResponse) {
    // Mirrors GraphQL/CardPriceHistory.graphql. Note `scryfallId_eq` is nested
    // under `identifiers` — CardEntityFilterInput has no such field at its root.
    let query = """
      query CardPriceHistory($scryfallId: String!) {
        cards(
          filter: { identifiers: { scryfallId_eq: $scryfallId } }
          page: { take: 1, skip: 0 }
        ) {
          uuid
          name
          setCode
          prices { provider date cardType listType currency format price }
        }
      }
      """

    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let token = ProcessInfo.processInfo.environment["MTGGRAPHQL_TOKEN"] {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
    }
    request.httpBody = try JSONSerialization.data(withJSONObject: [
      "query": query,
      "operationName": "CardPriceHistory",
      "variables": ["scryfallId": scryfallID],
    ])

    let (data, response) = try await URLSession.shared.data(for: request)
    return (data, response as! HTTPURLResponse)
  }

  private struct Envelope: Decodable {
    let data: Payload?
    let errors: [GraphQLError]?

    struct Payload: Decodable {
      /// `Query.cards` is `[Card!]!`, so this is an array — empty, not null,
      /// when nothing matches the filter.
      let cards: [CardNode]?
      struct CardNode: Decodable {
        let uuid: String?
        let name: String?
        let setCode: String?
        let prices: [MTGGraphQLPriceRow]?
      }
    }

    struct GraphQLError: Decodable { let message: String }
  }

  @Test("Returns prices for a known card and maps them to a chartable series")
  func fetchesRealPriceHistory() async throws {
    let (data, response) = try await post()

    // 401/403 means the token is wrong; 429 means the hourly cap is spent.
    #expect(
      response.statusCode == 200,
      "HTTP \(response.statusCode): \(String(decoding: data, as: UTF8.self).prefix(400))"
    )

    // When exercising the proxy (MTGGRAPHQL_URL set), the response must carry
    // `__typename` — the proxy rebuilds the query and Apollo iOS cannot decode a
    // response without it. This is the exact regression that shipped a blank
    // chart: every other test parses with hand-rolled Codable and never noticed.
    if ProcessInfo.processInfo.environment["MTGGRAPHQL_URL"] != nil {
      #expect(
        String(decoding: data, as: UTF8.self).contains("__typename"),
        "proxy response is missing __typename — Apollo will fail to decode it"
      )
    }

    let envelope = try JSONDecoder().decode(Envelope.self, from: data)
    #expect(
      envelope.errors == nil,
      "GraphQL errors: \(envelope.errors?.map(\.message) ?? [])"
    )

    let card = try #require(envelope.data?.cards?.first, "filter matched no card")
    #expect(card.name == "Phelddagrif")
    let rows = try #require(card.prices, "card returned without a prices field")
    #expect(rows.isEmpty == false, "\(card.name ?? "card") came back with no price rows")

    // Whatever providers happen to be quoting today, at least one must yield a
    // drawable line — that is the contract the card detail view relies on.
    let providers = Set(rows.compactMap { $0.provider?.lowercased() })
    let histories = PriceProvider.allCases
      .filter { providers.contains($0.rawValue) }
      .map { provider in
        PriceHistoryMapper.makeHistory(
          cardID: scryfallID,
          rows: rows,
          provider: provider,
          listType: .retail,
          window: DateInterval(start: .distantPast, end: .distantFuture)
        )
      }

    #expect(
      histories.contains { $0.chartableKinds.isEmpty == false },
      """
      No provider yielded two or more dated points. \
      Providers seen: \(providers.sorted()). \
      Sample row: \(rows.first.map(String.init(describing:)) ?? "none")
      """
    )
  }
}
