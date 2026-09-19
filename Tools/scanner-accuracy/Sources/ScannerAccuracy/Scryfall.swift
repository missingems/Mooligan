import Foundation

/// Scryfall's API, at the pace it asks for: about 100 ms between requests.
actor Scryfall {
  private var lastRequest = ContinuousClock.now - .seconds(1)

  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

  /// A page of up to 175 printings, and how many the search matches in all.
  /// Playtest cards are left out: they aren't printed for play.
  func search(_ query: String, page: Int) async throws -> (cards: [ScryfallCard], total: Int) {
    var components = URLComponents(string: "https://api.scryfall.com/cards/search")!
    components.queryItems = [
      URLQueryItem(name: "q", value: "\(query) -is:playtest"),
      URLQueryItem(name: "unique", value: "prints"),
      URLQueryItem(name: "order", value: "released"),
      URLQueryItem(name: "page", value: String(page)),
    ]
    struct Page: Decodable {
      let data: [ScryfallCard]
      let totalCards: Int
    }
    let result = try decoder.decode(Page.self, from: await send(URLRequest(url: components.url!)))
    return (result.data, result.totalCards)
  }

  /// Printings by card id, 75 to a request.
  func cards(_ ids: [String]) async throws -> [ScryfallCard] {
    struct Collection: Decodable { let data: [ScryfallCard] }
    var cards: [ScryfallCard] = []
    for start in stride(from: 0, to: ids.count, by: 75) {
      var request = URLRequest(url: URL(string: "https://api.scryfall.com/cards/collection")!)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONEncoder().encode([
        "identifiers": ids[start..<min(start + 75, ids.count)].map { ["id": $0] },
      ])
      cards += try decoder.decode(Collection.self, from: await send(request)).data
    }
    return cards
  }

  private func send(_ request: URLRequest) async throws -> Data {
    try await Task.sleep(until: lastRequest + .milliseconds(100), clock: .continuous)
    lastRequest = .now
    var request = request
    request.setValue("MooliganScannerAccuracy/1.0", forHTTPHeaderField: "User-Agent")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    let (data, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
    return data
  }
}
