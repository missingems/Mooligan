import ComposableArchitecture
import Foundation
import ScryfallKit


public protocol GameSetRequestClient: Sendable {
  func getAllSets() async throws -> [MTGSet]
  func getSets(queryType: GameSetQueryType) async throws -> [MTGSet]
  func searchSets(containing name: String) async throws -> [MTGSet]
}

public enum GameSetQueryType: Equatable {
  case all
  case name(String)
}

public enum GameSetRequestClientKey: DependencyKey {
  public static let liveValue: any GameSetRequestClient = ScryfallClient()
  public static let previewValue: any GameSetRequestClient = MockGameSetRequestClient()
  public static let testValue: any GameSetRequestClient = MockGameSetRequestClient()
}

public extension DependencyValues {
  var gameSetRequestClient: any GameSetRequestClient {
    get { self[GameSetRequestClientKey.self] }
    set { self[GameSetRequestClientKey.self] = newValue }
  }
}

extension ScryfallClient: GameSetRequestClient {
  public func getSets(queryType: GameSetQueryType) async throws -> [MTGSet] {
    return switch queryType {
    case .all:
      try await getAllSets()
      
    case let .name(string):
      try await searchSets(containing: string)
    }
  }
  
  public func searchSets(containing name: String) async throws -> [MTGSet] {
    if name.isEmpty {
      return try await getAllSets()
    } else {
      let value = try await getSets().data.folded().filter { _value in
        let parentContainName = _value.model.name.range(of: name, options: .caseInsensitive) != nil
        let childContainsName = _value.folders.sorted(by: { $0.model.date > $1.model.date && $0.model.name > $1.model.name })
          .flatMap { $0.flattened() }.contains { $0.name.range(of: name, options: .caseInsensitive) != nil }
        
        return parentContainName || childContainsName
      }
      
      return value
        .flatMap { $0.flattened() }
    }
  }
  
  public func getAllSets() async throws -> [MTGSet] {
    return try await getSets().data.filter { !$0.digital }.flattened()
  }
}

private extension Array where Element == MTGSet {
  func filteredByName(_ name: String) async -> [MTGSet] {
    return []
  }
  
  func flattened() async -> [MTGSet] {
    return folded()
      .sorted(by: { $0.model.date > $1.model.date })
      .flatMap { $0.flattened() }
  }
  
  func folded() -> [Folder<MTGSet>] {
    var foldersByCode = [String: Folder<MTGSet>]()
    var rootFolders = [Folder<MTGSet>]()
    
    for folderInfo in self {
      let folder = Folder(model: folderInfo)
      foldersByCode[folderInfo.code] = folder
    }
    
    for folder in foldersByCode.values {
      if let parentCode = folder.model.parentSetCode, let parentFolder = foldersByCode[parentCode] {
        parentFolder.folders.append(folder)
        parentFolder.folders = parentFolder.folders.sorted(by: { $0.model.date > $1.model.date && $0.model.name > $1.model.name })
      } else {
        rootFolders.append(folder)
      }
    }
    
    return rootFolders
  }
}

private extension MTGSet {
  var date: Date {
    guard let releasedAt else { return Date() }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    if let date = dateFormatter.date(from: releasedAt) {
      return date
    } else {
      return Date()
    }
  }
}
