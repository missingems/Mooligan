@testable import CardDetail
import Testing

struct ToolbarRowsTests {
  @Test func threeItemsShouldShareOneRow() {
    #expect([1, 2, 3].toolbarRows() == [[1, 2, 3]])
  }

  @Test func fourItemsShouldGoTwoToARow() {
    #expect([1, 2, 3, 4].toolbarRows() == [[1, 2], [3, 4]])
  }
}
