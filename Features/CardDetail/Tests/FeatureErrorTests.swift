@testable import CardDetail
import Foundation
import Testing

struct FeatureErrorTests {
  @Test(
    "Feature error localized description",
    arguments: [
      FeatureError.failedToFetchSetIconURL(errorMessage: UUID().uuidString),
      FeatureError.failedToFetchVariants(errorMessage: UUID().uuidString),
    ]
  )
  func featureErrorDescription(_ error: FeatureError) async throws {
    switch error {
    case let .failedToFetchSetIconURL(errorMessage):
      #expect(error.localizedDescription == errorMessage)
      
    case let .failedToFetchVariants(errorMessage):
      #expect(error.localizedDescription == errorMessage)
    }
  }
}
