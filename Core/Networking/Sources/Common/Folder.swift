public final class Folder<Model>: Identifiable, Equatable {
  public var id: Model { model }
  public let isParent: Bool
  public let model: Model
  public var folders: [Folder<Model>] = []
  
  public init(
    model: Model,
    folders: [Folder<Model>] = []
  ) {
    self.model = model
    self.folders = folders
    isParent = folders.isEmpty == false
  }
  
  public func flattened() -> [Model] {
    var _models: [Model] = []
    
    func flatten(_ folder: Folder<Model>) {
      _models.append(folder.model)
      
      folder.folders.forEach { folder in
        flatten(folder)
      }
    }
    
    flatten(self)
    
    return _models
  }
  
  public static func == (lhs: Folder<Model>, rhs: Folder<Model>) -> Bool {
    lhs.id == rhs.id &&
    lhs.folders == rhs.folders &&
    lhs.isParent == rhs.isParent
  }
}
