import Foundation

/// How much of one kind of downloaded data is kept, and how old it is.
public struct StoredDataset: Equatable, Sendable {
  public var count: Int
  public var oldest: Date?
  public var newest: Date?
  /// The MTGJSON builds the rows were read from, newest first, for data that records one.
  public var builds: [String]

  public init(count: Int = 0, oldest: Date? = nil, newest: Date? = nil, builds: [String] = []) {
    self.count = count
    self.oldest = oldest
    self.newest = newest
    self.builds = builds
  }
}
