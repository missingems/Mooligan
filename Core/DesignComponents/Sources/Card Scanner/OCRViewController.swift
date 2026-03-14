#if canImport(UIKit)
import UIKit
import AVFoundation
import Vision
import CoreImage
import UIKit

final class OCRViewController: UIViewController {
  var didDetectCard: ((_ title: String, _ setCode: String) -> Void)?
  private let captureSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated)
  private var isProcessing = false
  nonisolated private let ciContext = CIContext()
  private let boundingBoxLayer = CAShapeLayer()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard
      let backCamera = AVCaptureDevice.default(for: .video),
      let input = try? AVCaptureDeviceInput(device: backCamera)
    else {
      return
    }
    
    captureSession.sessionPreset = .hd4K3840x2160
    if captureSession.canAddInput(input) {
      captureSession.addInput(input)
    }
    
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    if captureSession.canAddOutput(videoOutput) {
      captureSession.addOutput(videoOutput)
    }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = view.bounds
    view.layer.insertSublayer(previewLayer, at: 0)
    
    boundingBoxLayer.strokeColor = UIColor.green.cgColor
    boundingBoxLayer.lineWidth = 3
    boundingBoxLayer.fillColor = UIColor.green.withAlphaComponent(0.1).cgColor
    view.layer.addSublayer(boundingBoxLayer)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    Task(priority: .background) { [weak self] in
      self?.captureSession.startRunning()
    }
  }
  
  private func processOCR(on cardImage: CGImage?) throws {
    guard let cardImage else { return }
    let width = CGFloat(cardImage.width)
    let height = CGFloat(cardImage.height)
    
    let titleRect = CGRect(x: 0, y: 0, width: width, height: height * 0.3)
    let setRect = CGRect(x: 0, y: height * 0.85, width: width * 0.4, height: height * 0.15)
    
    guard
      let titleImg = cardImage.cropping(to: titleRect),
      let setImg = cardImage.cropping(to: setRect)
    else {
      isProcessing = false
      return
    }
    
    let titleReq = VNRecognizeTextRequest()
    titleReq.recognitionLevel = .accurate
    
    let setReq = VNRecognizeTextRequest()
    setReq.recognitionLevel = .accurate
    
    let handlerTitle = VNImageRequestHandler(cgImage: titleImg, options: [:])
    let handlerSet = VNImageRequestHandler(cgImage: setImg, options: [:])
    
    try handlerTitle.perform([titleReq])
    try handlerSet.perform([setReq])
    
    let title = titleReq.results?.first?.topCandidates(1).first?.string ?? ""
    let setRaw = setReq.results?.compactMap {
      $0.topCandidates(1).first?.string
    } ?? []
    
    let parsedSet = parseSet(setRaw)
    
    if !title.isEmpty && !parsedSet.isEmpty {
      didDetectCard?(title, parsedSet)
    }
    
    self.isProcessing = false
  }
  
  nonisolated private func parseSet(_ strings: [String]) -> String {
    let words = strings.flatMap {
      $0.components(separatedBy: .whitespacesAndNewlines)
    }
    
    var n = ""; var s = ""
    for word in words {
      let u = word.uppercased()
      if n.isEmpty, u.range(of: "^\\d{3,4}$", options: .regularExpression) != nil { n = u }
      else if s.isEmpty, u.count == 3 { s = u }
    }
    return s.isEmpty ? "" : "\(s) #\(n)"
  }
  
  nonisolated private func extractAndFlattenCard(from pixelBuffer: CVPixelBuffer?, observation: VNRectangleObserver.Corners) -> CGImage? {
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

extension OCRViewController: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    
    VNRectangleObserver(imageBuffer: imageBuffer)?.proccess { [weak self] corners in
      self?.drawBox(corners)
      
      try? self?.processOCR(
        on: self?.extractAndFlattenCard(
          from: imageBuffer,
          observation: corners
        )
      )
    }
  }
}

extension OCRViewController {
  private func drawBox(_ observation: VNRectangleObserver.Corners) {
    boundingBoxLayer.path = nil
    
    let converted = [
      observation.topLeft,
      observation.topRight,
      observation.bottomRight,
      observation.bottomLeft
    ].map { point -> CGPoint in
      previewLayer.layerPointConverted(
        fromCaptureDevicePoint: CGPoint(
          x: 1.0 - point.y,
          y: 1.0 - point.x
        )
      )
    }
    
    let path = UIBezierPath()
    path.move(to: converted[0])
    converted.dropFirst().forEach {
      path.addLine(to: $0)
    }
    path.close()
    
    boundingBoxLayer.path = path.cgPath
  }
}

fileprivate extension CGPoint {
  func scaled(_ size: CGSize) -> CGPoint {
    return CGPoint(x: self.x * size.width, y: self.y * size.height)
  }
}

#endif // canImport(UIKit)
