import ComposableArchitecture

public enum CardImageHashSyncManagerKey: DependencyKey {
  public static let liveValue: any CardImageHashSyncManagable = CardImageHashSyncManager()
  public static let previewValue: any CardImageHashSyncManagable = CardImageHashSyncManager()
  public static let testValue: any CardImageHashSyncManagable = CardImageHashSyncManager()
}
