import AVFoundation
import CoreImage
import Vision

final class OCRCaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
  var onDrawBox: ((VNRectangleObserver.Corners?) -> Void)?
  var onDetectCard: ((OCRCardScannedResult) -> Void)?
  
  private var isProcessing = false
  private let ciContext = CIContext()
  
  private final class SendableImageBuffer: @unchecked Sendable {
    let value: CVImageBuffer
    init(_ value: CVImageBuffer) { self.value = value }
  }
  
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard !isProcessing else {
      return
    }
    
    defer {
      isProcessing = false
    }
    
    isProcessing = true
    
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }
    
    let sendableBuffer = SendableImageBuffer(imageBuffer)
    
    guard let observer = VNRectangleObserver(imageBuffer: imageBuffer) else { return }
    
    guard let corners = observer.process() else {
      DispatchQueue.main.async { [weak self] in
        self?.onDrawBox?(nil)
      }
      
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      self?.onDrawBox?(corners)
    }
    
    processOCR(
      on: extractAndFlattenCard(
        from: sendableBuffer.value,
        observation: corners
      )
    )
  }
  
  private func processOCR(on cardImage: CGImage?) {
    guard let cardImage else {
      return
    }
    
    let width = CGFloat(cardImage.width)
    let height = CGFloat(cardImage.height)
    
    let titleRect = CGRect(x: 0, y: 0, width: width, height: height * 0.15)
    let setRect = CGRect(x: 0, y: height * 0.92, width: width * 0.5, height: height * 0.08)
    
    guard
      let titleImg = cardImage.cropping(to: titleRect),
      let setImg = cardImage.cropping(to: setRect)
    else {
      return
    }
    
    let titleReq = VNRecognizeTextRequest()
    titleReq.recognitionLevel = .accurate
    
    let setReq = VNRecognizeTextRequest()
    setReq.recognitionLevel = .accurate
    
    try? VNImageRequestHandler(cgImage: titleImg, options: [:]).perform([titleReq])
    try? VNImageRequestHandler(cgImage: setImg, options: [:]).perform([setReq])
    
    let title = titleReq.results?.first?.topCandidates(1).first?.string ?? ""
    let parsedSetAndCode = parseSetAndCode(
      setReq.results?.compactMap {
        $0.topCandidates(1).first?.string
      } ?? []
    )
    
    guard !title.isEmpty else { return }
    
    let callback = onDetectCard
    DispatchQueue.main.async {
      callback?(
        OCRCardScannedResult(
          title: title,
          set: parsedSetAndCode?.set,
          code: parsedSetAndCode?.code
        )
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
      
      if set.isEmpty, cleaned.range(of: "^[A-Z][A-Z0-9]{2}$", options: .regularExpression) != nil {
        set = cleaned
      }
      
      if code.isEmpty {
        let parts = cleaned.components(separatedBy: "/")
        if let firstPart = parts.first, firstPart.range(of: "^\\d{3,4}$", options: .regularExpression) != nil {
          code = firstPart
        }
      }
    }
    
    if set.isEmpty || code.isEmpty { return nil }
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

fileprivate extension CGPoint {
  func scaled(_ size: CGSize) -> CGPoint {
    CGPoint(x: x * size.width, y: y * size.height)
  }
}
