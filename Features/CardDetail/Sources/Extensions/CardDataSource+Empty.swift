import Networking

extension CardDataSource {
  static var empty: CardDataSource { CardDataSource(cards: [], hasNextPage: false, total: 0) }
}
