import Foundation
import ScryfallKit

public struct BrowseRequest: Request {
  public let client: BrowseRequestClient
  
  public init() {
    client = ScryfallClient(networkLogLevel: .minimal)
  }
}
