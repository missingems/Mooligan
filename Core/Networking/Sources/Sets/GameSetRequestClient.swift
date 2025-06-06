import ComposableArchitecture
import Foundation
import ScryfallKit

public protocol GameSetRequestClient: Sendable {
  func getAllSets() async throws -> [MTGSet]
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
  public func getAllSets() async throws -> [MTGSet] {
    return try await getSets().data.filter { !$0.digital }.folders()
  }
}

private extension Array where Element == MTGSet {
  func folders() async -> [MTGSet] {
    return buildFolderTree(from: self)
      .sorted(by: { $0.model.date > $1.model.date })
      .flatMap { $0.flattened() }
  }
  
  func buildFolderTree(from flatFolders: [MTGSet]) -> [Folder<MTGSet>] {
    var foldersByCode = [String: Folder<MTGSet>]()
    var rootFolders = [Folder<MTGSet>]()
    
    for folderInfo in flatFolders {
      let folder = Folder(model: folderInfo)
      foldersByCode[folderInfo.code] = folder
    }
    
    for folder in foldersByCode.values {
      if let parentCode = folder.model.parentSetCode, let parentFolder = foldersByCode[parentCode] {
        parentFolder.folders.append(folder)
        parentFolder.folders = parentFolder.folders.sorted(by: { $0.model.date > $1.model.date })
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
