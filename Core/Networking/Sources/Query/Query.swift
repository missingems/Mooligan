import ScryfallKit

public struct Query: Equatable, Hashable {
  public var name: String {
    didSet {
      page = 1
    }
  }
  
  public var setCode: String {
    didSet {
      page = 1
    }
  }
  
  public var page: Int
  
  public var sortMode: SortMode {
    didSet {
      page = 1
    }
  }
  
  public var sortDirection: SortDirection {
    didSet {
      page = 1
    }
  }
  
  public init(
    name: String = "",
    setCode: String,
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
  
  func filters() -> [CardFieldFilter] {
    var filters: [CardFieldFilter] = []
    
    if name.isEmpty == false {
      filters.append(.name(name))
    }
    
    filters.append(.set(setCode))
    filters.append(.game(.paper))
    filters.append(.game(.mtgo))
    
    return filters
  }
  
  public mutating func next() -> Self {
    page += 1
    return self
  }
}
