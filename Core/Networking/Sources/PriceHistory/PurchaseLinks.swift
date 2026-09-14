import ComposableArchitecture
import Foundation
import ScryfallKit

public struct PurchaseLink: Sendable, Equatable, Hashable, Identifiable {
  public let provider: PriceProvider
  public let finish: PriceSeriesKind?
  public let url: URL

  public init(provider: PriceProvider, finish: PriceSeriesKind?, url: URL) {
    self.provider = provider
    self.finish = finish
    self.url = url
  }

  public var id: String { "\(provider.rawValue).\(finish?.rawValue ?? "all")" }
}

public struct MTGGraphQLPurchaseUrls: Sendable, Equatable, Decodable {
  public let tcgplayer: String?
  public let cardKingdom: String?
  public let cardKingdomFoil: String?
  public let cardmarket: String?

  public init(
    tcgplayer: String? = nil,
    cardKingdom: String? = nil,
    cardKingdomFoil: String? = nil,
    cardmarket: String? = nil
  ) {
    self.tcgplayer = tcgplayer
    self.cardKingdom = cardKingdom
    self.cardKingdomFoil = cardKingdomFoil
    self.cardmarket = cardmarket
  }
}

public enum PurchaseLinksMapper {
  public static func makeLinks(from urls: MTGGraphQLPurchaseUrls?) -> [PurchaseLink] {
    guard let urls else { return [] }

    let candidates: [(PriceProvider, PriceSeriesKind?, String?)] = [
      (.tcgplayer, nil, urls.tcgplayer),
      (.cardkingdom, .normal, urls.cardKingdom),
      (.cardkingdom, .foil, urls.cardKingdomFoil),
      (.cardmarket, nil, urls.cardmarket),
    ]

    return candidates.compactMap { provider, finish, raw in
      guard let url = secureURL(raw) else { return nil }
      return PurchaseLink(provider: provider, finish: finish, url: url)
    }
  }

  static func secureURL(_ raw: String?) -> URL? {
    guard
      let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
      trimmed.isEmpty == false,
      let components = URLComponents(string: trimmed),
      components.scheme?.lowercased() == "https",
      components.host?.isEmpty == false
    else {
      return nil
    }
    return components.url
  }
}

public enum ScryfallPurchaseLinks {
  public static func makeLinks(for card: Card) -> [PurchaseLink] {
    let prices = card.prices
    let storefronts: [(PriceProvider, String, [(PriceSeriesKind, String?)])] = [
      (.tcgplayer, "tcgplayer", [(.normal, prices.usd), (.foil, prices.usdFoil), (.etched, prices.usdEtched)]),
      (.cardmarket, "cardmarket", [(.normal, prices.eur), (.foil, prices.eurFoil), (.etched, prices.eurEtched)]),
    ]

    return storefronts.flatMap { provider, key, quotes -> [PurchaseLink] in
      guard let url = PurchaseLinksMapper.secureURL(card.purchaseUris?[key]) else { return [] }

      let quoted = quotes.compactMap { kind, raw -> PriceSeriesKind? in
        guard let raw, raw.trimmingCharacters(in: .whitespaces).isEmpty == false else { return nil }
        return kind
      }
      guard quoted.isEmpty == false else {
        return [PurchaseLink(provider: provider, finish: nil, url: url)]
      }
      return quoted.map { PurchaseLink(provider: provider, finish: $0, url: url) }
    }
  }
}

public protocol PurchaseLinksClient: Sendable {
  func purchaseLinks(for card: Card) async throws -> [PurchaseLink]
}

public struct FallbackPurchaseLinksClient: PurchaseLinksClient {
  private let primary: any PurchaseLinksClient

  public init(primary: any PurchaseLinksClient) {
    self.primary = primary
  }

  public func purchaseLinks(for card: Card) async throws -> [PurchaseLink] {
    let links: [PurchaseLink]
    do {
      links = try await primary.purchaseLinks(for: card)
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      return ScryfallPurchaseLinks.makeLinks(for: card)
    }
    return links.isEmpty ? ScryfallPurchaseLinks.makeLinks(for: card) : links
  }
}

public struct UnavailablePurchaseLinksClient: PurchaseLinksClient {
  public init() {}

  public func purchaseLinks(for card: Card) async throws -> [PurchaseLink] {
    throw PriceHistoryClientError.notConfigured
  }
}

#if DEBUG
public struct MockPurchaseLinksClient: PurchaseLinksClient {
  public init() {}

  public func purchaseLinks(for card: Card) async throws -> [PurchaseLink] {
    let token = card.id.uuidString.lowercased()
    return PurchaseLinksMapper.makeLinks(
      from: MTGGraphQLPurchaseUrls(
        tcgplayer: "https://mtgjson.com/links/tcgplayer-\(token)",
        cardKingdom: "https://mtgjson.com/links/cardkingdom-\(token)",
        cardKingdomFoil: "https://mtgjson.com/links/cardkingdom-foil-\(token)",
        cardmarket: "https://mtgjson.com/links/cardmarket-\(token)"
      )
    )
  }
}
#endif

public enum PurchaseLinksClientKey: DependencyKey {
  public static var liveValue: any PurchaseLinksClient {
#if MTGGRAPHQL_GENERATED
    FallbackPurchaseLinksClient(primary: ApolloPurchaseLinksClient())
#else
    FallbackPurchaseLinksClient(primary: UnavailablePurchaseLinksClient())
#endif
  }

#if DEBUG
  public static let previewValue: any PurchaseLinksClient = MockPurchaseLinksClient()
  public static let testValue: any PurchaseLinksClient = MockPurchaseLinksClient()
#endif
}

public extension DependencyValues {
  var purchaseLinksClient: any PurchaseLinksClient {
    get { self[PurchaseLinksClientKey.self] }
    set { self[PurchaseLinksClientKey.self] = newValue }
  }
}
