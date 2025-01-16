import ScryfallKit

public struct Query: Equatable, Hashable {
  public var name: String
  public var setCode: String?
  public var page: Int
  public var sortMode: SortMode
  public var sortDirection: SortDirection
  
  public init(
    name: String = "",
    setCode: String? = nil,
    page: Int,
    sortMode: SortMode,
    sortDirection: SortDirection
  ) {
    self.name = name
    self.page = page
    self.setCode = setCode
    self.sortMode = sortMode
    self.sortDirection = sortDirection
  }
}
