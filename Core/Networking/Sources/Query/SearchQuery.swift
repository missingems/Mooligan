import ScryfallKit

public struct SearchQuery: Equatable, Hashable {
  public enum CardType: String, CaseIterable, Hashable, Identifiable {
    public var id: String {
      return self.rawValue
    }
    
    case all
    case land
    case artifact
    case enchantment
    case instant
    case sorcery
    case planeswalker
    case creature
    
    public var title: String {
      return switch self {
      case .all: "All"
      case .land: "Land"
      case .artifact: "Artifact"
      case .enchantment: "Enchantment"
      case .instant: "Instant"
      case .sorcery: "Sorcery"
      case .planeswalker: "Planeswalker"
      case .creature: "Creature"
      }
    }
  }
  
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
  
  public var cardType: CardType {
    didSet {
      page = 1
    }
  }
  
  public var page: Int
  
  public var colorIdentities: [Card.Color] = Card.Color.allCases {
    didSet {
      page = 1
    }
  }
  
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
    cardType: CardType = .all,
    setCode: String,
    page: Int,
    sortMode: SortMode,
    sortDirection: SortDirection
  ) {
    self.name = name
    self.cardType = cardType
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
    
    if cardType != .all {
      // By default, all means without any type filter.
      filters.append(.compoundOr([.type(cardType.rawValue)]))
    }
    
    if colorIdentities.isEmpty == false {
      for identity in colorIdentities {
        filters.append(.colors(identity.rawValue, .including))
      }
    }
    
    return filters
  }
  
  public mutating func next() -> Self {
    page += 1
    return self
  }
}
