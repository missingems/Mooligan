import Foundation

/// MTGJSON's current build version, asked for at most once an hour.
///
/// `Meta.json` is a hundred-odd bytes and answers in well under a second, which makes it a cheap
/// way to find out whether anything stored is still current without touching a set file or the
/// price feed. MTGJSON builds once a day at most, so an hour between asks is plenty to notice a
/// new one within a session. A failure is not an error: it returns nil, and callers treat what
/// they have stored as good.
public actor MTGJSONBuild {
  /// Shared so every stored dataset is judged against the same answer, asked for once.
  public static let shared = MTGJSONBuild()

  private let session: URLSession
  private var answer: (version: String?, askedAt: Date)?
  private var asksAgainAt = Date.distantPast

  init(session: URLSession? = nil) {
    if let session {
      self.session = session
    } else {
      let configuration = URLSessionConfiguration.default
      configuration.timeoutIntervalForRequest = 5
      configuration.timeoutIntervalForResource = 5
      self.session = URLSession(configuration: configuration)
    }
  }

  public func version() async -> String? {
    if let answer, Date() < asksAgainAt {
      return answer.version
    }

    let value = await fetch()
    answer = (value, Date())
    // A failed ask is only remembered for a minute, so coming back online finds the build soon.
    asksAgainAt = Date().addingTimeInterval(value == nil ? 60 : 60 * 60)
    return value
  }

  /// The last answer and when it was asked, without asking again.
  public func lastAnswer() -> (version: String?, askedAt: Date)? {
    answer
  }

  private func fetch() async -> String? {
    guard let url = URL(string: "https://mtgjson.com/api/v5/Meta.json") else { return nil }

    guard
      let (data, response) = try? await session.data(from: url),
      (response as? HTTPURLResponse)?.statusCode == 200,
      let meta = try? JSONDecoder().decode(MTGJSONMetaFile.self, from: data)
    else { return nil }

    return meta.data.version
  }
}
