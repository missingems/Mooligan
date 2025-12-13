import ScryfallKit

public struct SearchQuery: Equatable, Hashable, Sendable {
  public enum CardType: String, CaseIterable, Hashable, Identifiable, Comparable, Sendable {
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
    
    public static func < (lhs: CardType, rhs: CardType) -> Bool {
      let order: [CardType] = CardType.allCases
      return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
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
  
  public var cardType: Set<CardType> = [] {
    didSet {
      if oldValue.intersection(cardType).contains(.all) == false, cardType.contains(.all) {
        cardType = [.all]
      } else {
        cardType.remove(.all)
      }
      
      if cardType.isEmpty {
        cardType = [.all]
      }
      
      
      page = 1
    }
  }
  
  public var page: Int
  
  public var colorIdentities: Set<Card.Color> = [] {
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
    cardType: Set<CardType> = [.all],
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
    
    if cardType != [.all] {
      filters.append(.compoundOr(cardType.map { .type($0.rawValue) }))
    }
    
    if colorIdentities.isEmpty == false {
      filters.append(.colorIdentity(colorIdentities.map(\.rawValue).joined()))
      
      if colorIdentities.contains(.C) == false {
        filters.append(.colorIdentity(Card.Color.C.rawValue, .notEqual))
      }
    }
    
    return filters
  }
  
  public mutating func next() -> Self {
    page += 1
    return self
  }
}

public extension Set where Element == Card.Color {
  mutating func toggleSelection(for element: Element) {
    if self.contains(element) {
      self.remove(element)
    } else {
      self.insert(element)
    }
  }
}

public extension Set where Element == SearchQuery.CardType {
  mutating func toggleSelection(for element: Element) {
    if self.contains(element) {
      self.remove(element)
    } else {
      self.insert(element)
    }
  }
}
