//
//  BrowseRequest.swift
//  Networking
//
//  Created by Jun on 1/5/24.
//

import Foundation
import ScryfallKit

public protocol Set {
  var id: String { get }
  var numberOfCards: Int { get }
  var name: String { get }
  var iconURL: URL? { get }
}

protocol Request {
  var client: BrowseRequestClient { get }
}

public protocol BrowseRequestClient {
  func getAllSets() async throws -> [Set]
}

public struct BrowseRequest: Request {
  public let client: BrowseRequestClient
  
  public init() {
    client = ScryfallClient(networkLogLevel: .minimal)
  }
}

extension ScryfallClient: BrowseRequestClient {
  public func getAllSets() async throws -> [Set] {
    try await getSets().data
  }
}

extension MTGSet: Set {
  public var id: String {
    code
  }
  
  public var numberOfCards: Int {
    cardCount
  }
  
  public var iconURL: URL? {
    URL(string: iconSvgUri)
  }
}
