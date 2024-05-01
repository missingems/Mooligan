import Foundation
import OSLog
import ScryfallKit

public struct BrowseRequest: Request {
  public enum ClientType {
    case scryfall
    case mock(any BrowseRequestClient)
  }
  
  public let client: any BrowseRequestClient
  
  public init(_ clientType: ClientType = .scryfall) {
    switch clientType {
    case .scryfall:
      client = ScryfallClient(networkLogLevel: .minimal)
      
    case let .mock(client):
      self.client = client
    }
  }
}
