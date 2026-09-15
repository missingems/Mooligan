import Foundation
import Networking

public enum PurchaseLinksState: Equatable, Sendable {
  case idle
  case loading
  case loaded([PurchaseLink])
  case failed
}
