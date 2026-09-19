import Dependencies
import Foundation

public enum CardPullOddsSourceKey: DependencyKey {
  public static var liveValue: any CardPullOddsSource { MTGJSONCardPullOddsSource() }

#if DEBUG
  public static var previewValue: any CardPullOddsSource { MockCardPullOddsSource() }
  public static var testValue: any CardPullOddsSource { MockCardPullOddsSource(odds: nil) }
#endif
}
