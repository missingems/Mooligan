import AVFoundation
import CoreImage
import Vision
import UIKit

final class OCRCaptureDelegate: NSObject, @unchecked Sendable {
  var onDrawBox: ((VNRectangleObserver.Corners?) -> Void)?
  var onDetectCard: ((ScannedImage) -> Void)?
  
  private var isProcessing = false
  private let ciContext = CIContext(options: [.cacheIntermediates: false])
  
  private final class SendableImageBuffer: @unchecked Sendable {
    let value: CVImageBuffer
    init(_ value: CVImageBuffer) { self.value = value }
  }
  
  private func processOCR(on cardImage: CGImage?) {
    guard let cardImage else { return }
    
    let callback = onDetectCard
    DispatchQueue.main.async {
      callback?(
        ScannedImage(value: cardImage)
      )
    }
  }
  
  private func parseSetAndCode(_ strings: [String]) -> (set: String, code: String)? {
    let fullText = strings.joined(separator: " ")
    let words = fullText.components(separatedBy: .whitespaces)
    
    var code = ""
    var set = ""
    
    for word in words {
      let cleaned = word.trimmingCharacters(in: CharacterSet(charactersIn: "•.,"))
      
      if set.isEmpty, cleaned.range(of: "^[A-Z][A-Z0-9]{2,3}$", options: .regularExpression) != nil {
        set = cleaned
      }
      
      if code.isEmpty {
        let parts = cleaned.components(separatedBy: "/")
        if let firstPart = parts.first, firstPart.range(of: "^\\d{3,4}$", options: .regularExpression) != nil {
          code = firstPart
        }
      }
    }
    
    if set.isEmpty || code.isEmpty {
      return nil
    }
    
    return (set, code)
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
    guard !isProcessing else { return }
    isProcessing = true
    
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      isProcessing = false
      return
    }
    
    let sendableBuffer = SendableImageBuffer(imageBuffer)
    guard let observer = VNRectangleObserver(imageBuffer: imageBuffer) else {
      isProcessing = false
      return
    }
    
    guard let corners = observer.process() else {
      DispatchQueue.main.async { [weak self] in
        self?.onDrawBox?(nil)
      }
      isProcessing = false
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      self?.onDrawBox?(corners)
    }
    
    Task { [weak self] in
      guard let self else { return }
      defer { self.isProcessing = false }
      
      processOCR(
        on: extractAndFlattenCard(
          from: sendableBuffer.value,
          observation: corners
        )
      )
    }
  }
}

fileprivate extension CGPoint {
  func scaled(_ size: CGSize) -> CGPoint {
    CGPoint(x: x * size.width, y: y * size.height)
  }
}
