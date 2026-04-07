import SwiftUI

public struct OCRView: View {
  var isMorphed: Bool
  var onValidatedScan: (ScannedImage) -> Void
  var onTrackingUpdate: (QuadCorners?) -> Void
  
  public init(
    isMorphed: Bool,
    onValidatedScan: @escaping (ScannedImage) -> Void,
    onTrackingUpdate: @escaping (QuadCorners?) -> Void
  ) {
    self.isMorphed = isMorphed
    self.onValidatedScan = onValidatedScan
    self.onTrackingUpdate = onTrackingUpdate
  }
  
  public var body: some View {
    OCRViewRepresentable(
      isPaused: isMorphed,
      onValidatedScan: onValidatedScan,
      onTrackingUpdate: onTrackingUpdate
    )
  }
}

