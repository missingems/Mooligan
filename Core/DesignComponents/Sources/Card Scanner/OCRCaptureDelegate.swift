import AVFoundation
import CoreImage
import Vision
import UIKit

final class OCRCaptureDelegate: NSObject, @unchecked Sendable {
  var gatekeeper: ScannerGatekeeper?
  
  var onDrawBox: ((VNRectangleObserver.Corners?) -> Void)?
  var onDetectCard: ((CGImage, VNRectangleObserver.Corners) -> Void)?
  
  var isOCRDisabled = false
  var isTrackingDisabled = false
  
  private let ciContext = CIContext(options: [.cacheIntermediates: false])
  
  private final class SendableImageBuffer: @unchecked Sendable {
    let value: CVImageBuffer
    init(_ value: CVImageBuffer) { self.value = value }
  }
  
  private func processOCR(on cardImage: CGImage?, corners: VNRectangleObserver.Corners) {
    guard let cardImage else { return }
    let callback = onDetectCard
    DispatchQueue.main.async {
      callback?(cardImage, corners)
    }
  }
  
  private func extractAndFlattenCard(
    from pixelBuffer: CVPixelBuffer?,
    observation: VNRectangleObserver.Corners
  ) -> CGImage? {
    guard let pixelBuffer else { return nil }
    return VNRectangleObserver.flattenedCard(
      in: CIImage(cvPixelBuffer: pixelBuffer).oriented(.right),
      corners: observation,
      context: ciContext
    )
  }
}

extension OCRCaptureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard !isTrackingDisabled else { return }
    
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let sendableBuffer = SendableImageBuffer(imageBuffer)
    
    guard let observer = VNRectangleObserver(imageBuffer: imageBuffer),
          let corners = observer.process() else {
      DispatchQueue.main.async { [weak self] in self?.onDrawBox?(nil) }
      return
    }
    
    DispatchQueue.main.async { [weak self] in self?.onDrawBox?(corners) }
    
    guard !isOCRDisabled else { return }
    guard let gatekeeper = gatekeeper, gatekeeper.checkAndLockForProcessing() else { return }
    
    Task { [weak self] in
      guard let self else { return }
      processOCR(
        on: extractAndFlattenCard(from: sendableBuffer.value, observation: corners),
        corners: corners
      )
    }
  }
}
