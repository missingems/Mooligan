import DesignComponents
import Networking
import SwiftUI

extension String {
  func isEmptyOrNil() -> Bool {
    isEmpty || trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
