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
    
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
    let filter = CIFilter(name: "CIPerspectiveCorrection")
    filter?.setValue(ciImage, forKey: kCIInputImageKey)
    filter?.setValue(CIVector(cgPoint: observation.topLeft.scaled(ciImage.extent.size)), forKey: "inputTopLeft")
    filter?.setValue(CIVector(cgPoint: observation.topRight.scaled(ciImage.extent.size)), forKey: "inputTopRight")
    filter?.setValue(CIVector(cgPoint: observation.bottomLeft.scaled(ciImage.extent.size)), forKey: "inputBottomLeft")
    filter?.setValue(CIVector(cgPoint: observation.bottomRight.scaled(ciImage.extent.size)), forKey: "inputBottomRight")
    
    guard let output = filter?.outputImage else { return nil }
    return ciContext.createCGImage(output, from: output.extent)
  }
}

extension OCRCaptureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    // Stop immediately if tracking is disabled to save CPU
    guard !isTrackingDisabled else { return }
    
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let sendableBuffer = SendableImageBuffer(imageBuffer)
    
    guard let observer = VNRectangleObserver(imageBuffer: imageBuffer),
          let corners = observer.process() else {
      DispatchQueue.main.async { [weak self] in
        self?.onDrawBox?(nil)
      }
      return
    }
    
    // Pass bounding box up to SwiftUI
    DispatchQueue.main.async { [weak self] in
      self?.onDrawBox?(corners)
    }
    
    // Stop heavy OCR extraction if disabled
    guard !isOCRDisabled else { return }
    
    // 🚦 LOCK-CHECK-GO
    guard let gatekeeper = gatekeeper, gatekeeper.checkAndLockForProcessing() else {
      return // Frame dropped cleanly
    }
    
    Task { [weak self] in
      guard let self else { return }
      
      processOCR(
        on: extractAndFlattenCard(
          from: sendableBuffer.value,
          observation: corners
        ),
        corners: corners
      )
    }
  }
}

fileprivate extension CGPoint {
  func scaled(_ size: CGSize) -> CGPoint {
    CGPoint(x: x * size.width, y: y * size.height)
  }
}
