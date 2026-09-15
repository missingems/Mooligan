import Foundation

extension Array {
  /// Up to three items share one row; four or more go two to a row.
  func toolbarRows() -> [[Element]] {
    guard count > 3 else { return [self] }
    return stride(from: 0, to: count, by: 2).map { Array(self[$0..<Swift.min($0 + 2, count)]) }
  }
}
