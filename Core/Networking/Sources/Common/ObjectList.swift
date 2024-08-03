import Foundation

public struct ObjectList<Model: Equatable>: Equatable {
  public var model: Model
  public var hasNextPage: Bool = false
  
  public init(model: Model, hasNextPage: Bool = false) {
    self.model = model
    self.hasNextPage = hasNextPage
  }
}

public extension ObjectList where Model: Collection {
  func shouldFetchNextPage(at index: Int) -> Bool {
    return index == model.count - 1 && hasNextPage
  }
}

public extension ObjectList where Model: RangeReplaceableCollection {
  func updating(with value: ObjectList<Model>) -> Self {
    var copy = self
    copy.model.append(contentsOf: value.model)
    copy.hasNextPage = value.hasNextPage
    return copy
  }
}
