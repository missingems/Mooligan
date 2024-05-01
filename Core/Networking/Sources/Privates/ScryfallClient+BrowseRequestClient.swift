import ScryfallKit

extension ScryfallClient: BrowseRequestClient {
  public func getAllSets() async throws -> [Set] {
    try await getSets().data
  }
}
