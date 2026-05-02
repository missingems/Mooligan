import SwiftUI

public struct OCRView: View {
  var isScanningPaused: Bool
  var isProcessingFrame: Bool
  var isTrackingPaused: Bool
  var onValidatedScan: (ScannedImage) -> Void
  var onTrackingUpdate: (QuadCorners?) -> Void
  
  public init(
    isScanningPaused: Bool,
    isProcessingFrame: Bool,
    isTrackingPaused: Bool,
    onValidatedScan: @escaping (ScannedImage) -> Void,
    onTrackingUpdate: @escaping (QuadCorners?) -> Void
  ) {
    self.isScanningPaused = isScanningPaused
    self.isProcessingFrame = isProcessingFrame
    self.isTrackingPaused = isTrackingPaused
    self.onValidatedScan = onValidatedScan
    self.onTrackingUpdate = onTrackingUpdate
  }
  
  public var body: some View {
    OCRViewRepresentable(
      isScanningPaused: isScanningPaused,
      isProcessingFrame: isProcessingFrame,
      isTrackingPaused: isTrackingPaused,
      onValidatedScan: onValidatedScan,
      onTrackingUpdate: onTrackingUpdate
    )
  }
}
