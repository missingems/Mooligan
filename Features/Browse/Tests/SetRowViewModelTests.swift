@testable import Browse
import Networking
import Foundation
import SwiftUI
import XCTest

final class SetRowViewModelTests: XCTestCase {
  func test_init_staticProperties() {
    let viewModel = Self.makeViewModel()
    
    XCTAssertEqual(
      viewModel.childIndicatorImageName,
      "arrow.turn.down.right"
    )
    
    XCTAssertEqual(
      viewModel.disclosureIndicatorImageName,
      "chevron.right"
    )
    
    XCTAssertEqual(viewModel.iconUrl, URL(string: "mooligan.com"))
  }
  
  func test_lightMode() {
    let viewModel = Self.makeViewModel(colorScheme: .light)
    XCTAssertEqual(viewModel.colorScheme, .light)
  }
  
  func test_shouldSetBackground_whenIndexIsMultipleOfTwo_equalFalse_shouldReturnTrue() {
    let viewModel = Self.makeViewModel(index: 0)
    XCTAssertTrue(viewModel.shouldSetBackground)
  }
  
  func test_shouldSetBackground_whenIndexIsMultipleOfTwo_equalTrue_shouldReturnFalse() {
    let viewModel = Self.makeViewModel(index: 1)
    XCTAssertFalse(viewModel.shouldSetBackground)
  }
  
  func test_id_shouldBeUppercased() {
    let viewModel = Self.makeViewModel(code: "abc")
    XCTAssertEqual(viewModel.id, "ABC")
  }
  
  func test_numberOfCardsLabel() {
    let viewModel = Self.makeViewModel()
    XCTAssertEqual(viewModel.numberOfCardsLabel, "1 Cards")
  }
  
  func test_isSelected_equalsTrue() {
    let id = UUID()
    
    let given = MockGameSet(
      isParent: true,
      id: id,
      code: "abc",
      numberOfCards: 1,
      name: "title",
      iconURL: URL(string: "mooligan.com")
    )
    
    let viewModel = Self.makeViewModel(
      id: id,
      selectedSet: given
    )
    
    XCTAssertTrue(viewModel.isSelected)
  }
  
  func test_shouldShowIndentIndicator_whenIsParentEqualsTrue_shouldReturnFalse() {
    let viewModel = Self.makeViewModel(isParent: true)
    XCTAssertFalse(viewModel.shouldShowIndentIndicator)
  }
  
  func test_shouldShowIndentIndicator_whenIsParentEqualsFalse_shouldReturnTrue() {
    let viewModel = Self.makeViewModel(isParent: false)
    XCTAssertTrue(viewModel.shouldShowIndentIndicator)
  }
  
  static func makeViewModel(
    colorScheme: ColorScheme = .light,
    index: Int = 0,
    isParent: Bool = false,
    id: UUID = UUID(),
    code: String? = "abc",
    iconURL: URL? = URL(string: "mooligan.com"),
    selectedSet: MockGameSet? = nil
  ) -> SetRow.ViewModel {
    SetRow.ViewModel(
      set: MockGameSet(
        isParent: isParent,
        id: id,
        code: "abc",
        numberOfCards: 1,
        name: "title",
        iconURL: iconURL
      ), 
      selectedSet: selectedSet,
      index: index,
      colorScheme: colorScheme
    )
  }
}

