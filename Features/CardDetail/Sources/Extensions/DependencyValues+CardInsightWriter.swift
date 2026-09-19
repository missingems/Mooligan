import ComposableArchitecture
import Foundation

public extension DependencyValues {
  var cardInsightWriter: any CardInsightWriter {
    get { self[CardInsightWriterKey.self] }
    set { self[CardInsightWriterKey.self] = newValue }
  }
}
