import ComposableArchitecture
import Foundation
import ScryfallKit

public protocol GameSetRequestClient: Sendable {
  func getSets(queryType: GameSetQueryType) async throws -> ([ScryfallClient.SetsSection], [MTGSet])
  func getSets(queryType: GameSetQueryType, policy: CachePolicy) async throws -> ([ScryfallClient.SetsSection], [MTGSet])
}

public extension GameSetRequestClient {
  func getSets(queryType: GameSetQueryType, policy: CachePolicy) async throws -> ([ScryfallClient.SetsSection], [MTGSet]) {
    try await getSets(queryType: queryType)
  }
}

public enum GameSetQueryType: Equatable, Sendable {
  case all
  case name(String, [MTGSet])
}

public enum GameSetRequestClientKey: DependencyKey {
  public static var liveValue: any GameSetRequestClient { CachedGameSetRequestClient() }
#if DEBUG
  public static let previewValue: any GameSetRequestClient = MockGameSetRequestClient()
  public static let testValue: any GameSetRequestClient = MockGameSetRequestClient()
#endif
}

public extension DependencyValues {
  var gameSetRequestClient: any GameSetRequestClient {
    get { self[GameSetRequestClientKey.self] }
    set { self[GameSetRequestClientKey.self] = newValue }
  }
}

extension ScryfallClient: GameSetRequestClient {
  public struct SetsSection: Equatable, Identifiable {
    public var id = UUID()
    public let isUpcomingSet: Bool
    public let displayDate: String
    public let sets: [MTGSet]
  }
  
  static func filteredAndFoldedSets(from sets: [MTGSet]) -> [Folder<MTGSet>] {
    return sets.filter { !$0.digital }
      .folded()
      .filter {
        $0.model.cardCount != 0 || $0.folders.flatMap { $0.flattened() }.contains { $0.cardCount != 0 }
      }
  }
  
  static func makeSections(from folders: [Folder<MTGSet>]) -> [SetsSection] {
    let grouped = Dictionary(grouping: folders) { $0.model.date }
    return grouped.keys.sorted(by: >).compactMap { date in
      grouped[date].map { sets in
        SetsSection(
          isUpcomingSet: Date.now < date,
          displayDate: date.formatted(date: .abbreviated, time: .omitted),
          sets: sets.sorted { $0.model.cardCount > $1.model.cardCount }
            .flatMap { $0.flattened() }
            .filter { $0.cardCount != 0 }
        )
      }
    }
  }
  
  public func getSets(queryType: GameSetQueryType) async throws -> ([ScryfallClient.SetsSection], [MTGSet]) {
    switch queryType {
    case .all:
      let sets = try await getSets().data
      return (Self.sections(from: sets), sets)
      
    case let .name(name, existingSets):
      let sets = existingSets.isEmpty ? try await getSets().data : existingSets
      return (Self.sections(from: sets, matching: name), sets)
    }
  }
  
  static func sections(from sets: [MTGSet]) -> [SetsSection] {
    makeSections(from: filteredAndFoldedSets(from: sets))
  }
  
  static func sections(from sets: [MTGSet], matching name: String) -> [SetsSection] {
    let folded = filteredAndFoldedSets(from: sets)
    
    let filtered = folded.filter { folder in
      let parentContainsName = folder.model.name.range(of: name, options: .caseInsensitive) != nil
      let childContainsName = folder.folders.flatMap { $0.flattened() }
        .contains { $0.name.range(of: name, options: .caseInsensitive) != nil }
      return parentContainsName || childContainsName
    }
    
    return makeSections(from: filtered.isEmpty ? folded : filtered)
  }
}

private extension Array where Element == MTGSet {
  func folded() -> [Folder<MTGSet>] {
    let foldersByCode = Dictionary(uniqueKeysWithValues: map {
      ($0.code, Folder(model: $0)) }
    )
    
    var rootFolders: [Folder<MTGSet>] = []
    
    for folder in foldersByCode.values {
      if
        let parentCode = folder.model.parentSetCode,
        let parentFolder = foldersByCode[parentCode]
      {
        parentFolder.folders.append(folder)
        parentFolder.folders = parentFolder.folders.sorted { $0.model.name > $1.model.name }
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
