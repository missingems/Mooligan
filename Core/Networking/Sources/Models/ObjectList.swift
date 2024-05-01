import Foundation

public struct ObjectList<Model: GameSet>: Equatable {
  public let sets: [Model]
  
  public init(sets: [Model] = []) {
    self.sets = sets
  }
}
