import Foundation

/// Where the app sends GraphQL.
///
/// The app never holds an MTGGraphQL access token. Tokens are issued per Patreon
/// subscriber and capped at 500 requests/hour, so a token shipped inside the
/// binary would be extractable by anyone and shared across every install — one
/// user's browsing would exhaust the quota for all of them.
///
/// Instead the app talks to a small proxy (see `Tools/mtggraphql-proxy/`) that
/// holds the token as a server-side secret, forwards the one allow-listed
/// operation upstream, and caches responses. No secret ships in the IPA.
public struct MTGGraphQLEndpoint: Sendable {
  public let url: URL

  public init(url: URL) {
    self.url = url
  }

  /// Reads `MTGGraphQLProxyURL` from the main bundle's Info.plist, which resolves
  /// from the `MTGGRAPHQL_PROXY_URL` build setting (see `Mooligan/Secrets.xcconfig`).
  /// Returns nil rather than a hardcoded host when it is unset — an undefined
  /// build setting expands to an empty string, and a half-configured build (the
  /// literal `$(MTGGRAPHQL_PROXY_URL)` left unexpanded) must not become a live
  /// endpoint either, hence the explicit `https://` requirement.
  public static func fromBundle(_ bundle: Bundle = .main) -> MTGGraphQLEndpoint? {
    guard
      let raw = (bundle.object(forInfoDictionaryKey: "MTGGraphQLProxyURL") as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      raw.hasPrefix("https://"),
      let url = URL(string: raw)
    else {
      return nil
    }
    return MTGGraphQLEndpoint(url: url)
  }
}
