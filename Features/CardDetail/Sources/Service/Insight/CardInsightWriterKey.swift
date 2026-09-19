import ComposableArchitecture
import Foundation

public enum CardInsightWriterKey: DependencyKey {
  public static var liveValue: any CardInsightWriter { FoundationModelsInsightWriter() }

#if DEBUG
  public static var previewValue: any CardInsightWriter { MockCardInsightWriter() }
  public static var testValue: any CardInsightWriter { MockCardInsightWriter(snapshots: nil) }
#endif
}
