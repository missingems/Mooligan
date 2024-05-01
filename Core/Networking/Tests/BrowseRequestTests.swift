import Foundation
import ScryfallKit
import XCTest

final class BrowseRequestTests: XCTestCase {
  func testDefaultClient_isScryfall() {
    let request = BrowseRequest()
    
    XCTAssertTrue(request.client is ScryfallClient)
  }
  
  func testMockClient_returnsCorrectTyoe() {
    let mockClient = MockBrowseRequestClient()
    let request = BrowseRequest(.mock(mockClient))
    
    XCTAssertTrue(request.client is MockBrowseRequestClient)
  }
}
