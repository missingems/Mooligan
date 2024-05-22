import Foundation

public struct ObjectList<Model: Equatable>: Equatable {
  public var model: Model
  public var hasNextPage: Bool = false
  
  public init(model: Model, hasNextPage: Bool = false) {
    self.model = model
    self.hasNextPage = hasNextPage
  }
}
