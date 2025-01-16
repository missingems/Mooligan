import ScryfallKit

extension SortDirection: @retroactive Identifiable {
  public nonisolated var id: Self {
    return self
  }
  
  public var description: String {
    switch self {
    case .asc:
      return String(localized: "Ascending")
    case .desc:
      return String(localized: "Descending")
    case .auto:
      return String(localized: "Auto")
    }
  }
}
