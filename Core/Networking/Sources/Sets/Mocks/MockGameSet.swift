import Foundation

public struct MockGameSet: GameSet {
  public var isParent: Bool? = false
  public var id = UUID()
  public var code = "OTJ"
  public var numberOfCards = 1
  public var name = "Stub"
  public var iconURL = URL(string: "https://mooligan.com")
  
  public init(
    isParent: Bool? = false,
    id: UUID = UUID(),
    code: String = "OTJ",
    numberOfCards: Int = 1,
    name: String = "Stub",
    iconURL: URL? = URL(string: "https://mooligan.com")
  ) {
    self.isParent = isParent
    self.id = id
    self.code = code
    self.numberOfCards = numberOfCards
    self.name = name
    self.iconURL = iconURL
  }
}
