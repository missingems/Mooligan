public struct ObjectList<Model>: Equatable {
  public let sets: [Model]
  
  public init(sets: [Model] = []) {
    self.sets = sets
  }
  
  public static func == (lhs: ObjectList<Model>, rhs: ObjectList<Model>) -> Bool {
    return true
  }
}
