@testable import Networking
import Foundation
import ScryfallKit

final class SpyGameSetRequestClient: GameSetRequestClient, @unchecked Sendable {
  private let lock = NSLock()
  private var _sets: [MTGSet]
  private var _callCount = 0
  private var _error: (any Error)?

  init(sets: [MTGSet] = MockGameSetRequestClient.mockSets) {
    _sets = sets
  }

  var callCount: Int { lock.withLock { _callCount } }

  func setSets(_ sets: [MTGSet]) { lock.withLock { _sets = sets } }
  func setError(_ error: (any Error)?) { lock.withLock { _error = error } }

  func getSets(
    queryType: GameSetQueryType
  ) async throws -> ([ScryfallClient.SetsSection], [MTGSet]) {
    try lock.withLock {
      _callCount += 1
      if let _error { throw _error }
      return (ScryfallClient.sections(from: _sets), _sets)
    }
  }
}

final class SpyCardQueryRequestClient: MagicCardQueryRequestClient, @unchecked Sendable {
  private let lock = NSLock()
  private var _pages: [Int: [Card]] = [:]
  private var _totalCards = 0
  private var _callCount = 0
  private var _requestedPages: [Int] = []
  private var _error: (any Error)?
  private var _card: Card = CardFixtures.card()

  init(pages: [Int: [Card]] = [:], totalCards: Int = 0) {
    _pages = pages
    _totalCards = totalCards
  }

  var callCount: Int { lock.withLock { _callCount } }
  var requestedPages: [Int] { lock.withLock { _requestedPages } }

  func setPages(_ pages: [Int: [Card]], totalCards: Int) {
    lock.withLock {
      _pages = pages
      _totalCards = totalCards
    }
  }

  func setError(_ error: (any Error)?) { lock.withLock { _error = error } }
  func setCard(_ card: Card) { lock.withLock { _card = card } }

  func queryCards(_ query: SearchQuery) async throws -> ObjectList<Card> {
    try lock.withLock {
      _callCount += 1
      _requestedPages.append(query.page)
      if let _error { throw _error }

      let cards = _pages[query.page] ?? []
      return ObjectList(
        data: cards,
        hasMore: _pages.keys.contains(query.page + 1),
        nextPage: nil,
        totalCards: _totalCards
      )
    }
  }

  func queryCard(for id: String) async throws -> Card {
    try lock.withLock {
      _callCount += 1
      if let _error { throw _error }
      return _card
    }
  }

  func randomlyQueryErrorCard() async throws -> Card {
    lock.withLock {
      _callCount += 1
      return _card
    }
  }
}

enum QueryFixtures {
  static func setBrowse(
    setCode: String = "fdn",
    page: Int = 1,
    sortMode: SortMode = .name,
    sortDirection: SortDirection = .asc
  ) -> SearchQuery {
    SearchQuery(
      setCode: setCode, page: page, sortMode: sortMode, sortDirection: sortDirection
    )
  }
}

struct StubError: Error, Equatable {}

final class SpyCardDetailRequestClient: MagicCardDetailRequestClient, @unchecked Sendable {
  private let lock = NSLock()
  private var _set = MockGameSetRequestClient.mockSets[0]
  private var _variants: [Card] = []
  private var _related: CardDataSource?
  private var _getSetCount = 0
  private var _getVariantsCount = 0
  private var _getRelatedCount = 0
  private var _getRulingsCount = 0

  var getSetCount: Int { lock.withLock { _getSetCount } }
  var getVariantsCount: Int { lock.withLock { _getVariantsCount } }
  var getRelatedCount: Int { lock.withLock { _getRelatedCount } }
  var getRulingsCount: Int { lock.withLock { _getRulingsCount } }

  func setSet(_ set: MTGSet) { lock.withLock { _set = set } }
  func setVariants(_ cards: [Card]) { lock.withLock { _variants = cards } }
  func setRelated(_ source: CardDataSource?) { lock.withLock { _related = source } }

  func getRulings(of card: Card) async throws -> [MagicCardRuling] {
    lock.withLock {
      _getRulingsCount += 1
      return []
    }
  }

  func getVariants(of card: Card, page: Int) async throws -> ObjectList<Card> {
    lock.withLock {
      _getVariantsCount += 1
      return ObjectList(
        data: _variants, hasMore: false, nextPage: nil, totalCards: _variants.count
      )
    }
  }

  func getRelatedCardsIfNeeded(
    of card: Card,
    for type: Card.RelatedCard.Component
  ) async throws -> CardDataSource? {
    lock.withLock {
      _getRelatedCount += 1
      return _related
    }
  }

  func getSet(of card: Card) async throws -> MTGSet {
    lock.withLock {
      _getSetCount += 1
      return _set
    }
  }
}
