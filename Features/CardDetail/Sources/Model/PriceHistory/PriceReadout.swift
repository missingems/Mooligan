import Foundation
import Networking

struct PriceReadout: Equatable {
  let point: PricePoint
  let change: PriceChange?
  let isScrubbing: Bool
}
