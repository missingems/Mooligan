import ScryfallKit

public struct Query {
  public private(set) var name: String
  public private(set) var setCode: String?
  public private(set) var page: Int
  public private(set) var sortMode: SortMode
  public private(set) var sortDirection: SortDirection
  
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
  
  public mutating func updating(name: String) -> Self {
    self.name = name
    page = 1
    return self
  }
  
  public mutating func updating(setCode: String?) -> Self {
    self.setCode = setCode
    page = 1
    return self
  }
  
  public mutating func updating(page: Int) -> Self {
    self.page = page
    return self
  }
  
  public mutating func updating(sortMode: SortMode) -> Self {
    self.sortMode = sortMode
    page = 1
    return self
  }
  
  public mutating func updating(sortDirection: SortDirection) -> Self {
    self.sortDirection = sortDirection
    page = 1
    return self
  }
}
