import DesignComponents
import Foundation
import Networking
import SwiftUI

extension Decimal {
  var doubleValue: Double { (self as NSDecimalNumber).doubleValue }
}
