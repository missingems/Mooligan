import ComposableArchitecture
import Foundation
import ScryfallKit


public protocol GameSetRequestClient: Sendable {
  func getSets(queryType: GameSetQueryType) async throws -> ([ScryfallClient.SetsSection], [MTGSet])
}

public enum GameSetQueryType: Equatable {
  case all
  case name(String, [MTGSet])
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
  public struct SetsSection: Equatable, Identifiable {
    public var id: Date {
      return self.date
    }
    public let date: Date
    public let sets: [MTGSet]
  }
  
  public func getSets(queryType: GameSetQueryType) async throws -> ([ScryfallClient.SetsSection], [MTGSet]) {
    switch queryType {
    case .all:
      let sets = try await getSets().data
      let foldeded = sets.filter { !$0.digital }.folded()
      
      let grouped = Dictionary(grouping: foldeded) { folder in
        return folder.model.date
      }
      
      let sortedGroups = grouped.keys.sorted(by: >).map { date in
        return SetsSection(date: date, sets: grouped[date]!
          .flatMap { $0.flattened() })
      }
      
      return (sortedGroups, sets)
      
    case let .name(name, existingSets):
      let sets: [MTGSet]
      
      if existingSets.isEmpty == false {
        sets = existingSets
      } else {
        sets = try await getSets().data
      }
      
      let foldeded = sets.filter { !$0.digital }.folded()
      
      let date = Date()
      
      var filteredSets = sets.filter { !$0.digital }.folded().filter { _value in
        let parentContainName = _value.model.name.range(of: name, options: .caseInsensitive) != nil
        
        let childContainsName = _value.folders.flatMap {
          $0.flattened()
        }.contains {
          $0.name.range(of: name, options: .caseInsensitive) != nil
        }
        
        return parentContainName || childContainsName
      }
      
      if filteredSets.isEmpty {
        filteredSets = sets.folded()
      }
      
      let grouped = Dictionary(grouping: filteredSets) { folder in
        return folder.model.date
      }
      
      let sortedGroups = grouped.keys.sorted(by: >).map { date in
        return SetsSection(date: date, sets: grouped[date]!
          .flatMap { $0.flattened() })
      }
      print("Date diff: ", Date().timeIntervalSince(date))
      return (sortedGroups, sets)
    }
  }
}

private extension Array where Element == MTGSet {
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
      .sorted(by: { $0.model.date > $1.model.date })
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
