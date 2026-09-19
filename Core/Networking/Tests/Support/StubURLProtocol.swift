import Foundation

/// Answers requests from canned responses keyed by URL, and counts them, so a
/// source can be tested without the network. Tests keep apart by asking for
/// different URLs.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
  private static let lock = NSLock()
  nonisolated(unsafe) private static var responses: [URL: (status: Int, body: Data)] = [:]
  nonisolated(unsafe) private static var counts: [URL: Int] = [:]

  static func stub(_ url: URL, status: Int = 200, body: String = "") {
    lock.withLock { responses[url] = (status, Data(body.utf8)) }
  }

  static func requestCount(for url: URL) -> Int {
    lock.withLock { counts[url] ?? 0 }
  }

  static func session() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return URLSession(configuration: configuration)
  }

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    guard let url = request.url else { return }
    let response = Self.lock.withLock {
      Self.counts[url, default: 0] += 1
      return Self.responses[url]
    }

    guard let response else {
      client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
      return
    }

    let http = HTTPURLResponse(url: url, statusCode: response.status, httpVersion: nil, headerFields: nil)!
    client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: response.body)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}
