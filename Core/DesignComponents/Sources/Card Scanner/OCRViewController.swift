import UIKit
import AVFoundation
import Vision
import CoreImage

final class OCRViewController: UIViewController {
  var didDetectCard: ((_ title: String, _ setCode: String) -> Void)?
  
  private let captureSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated)
  private let boundingBoxLayer = CAShapeLayer()
  private var captureDelegate: CaptureDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard
      let backCamera = AVCaptureDevice.default(for: .video),
      let input = try? AVCaptureDeviceInput(device: backCamera)
    else { return }
    
    captureSession.sessionPreset = .hd4K3840x2160
    
    if captureSession.canAddInput(input) {
      captureSession.addInput(input)
    }
    
    let delegate = CaptureDelegate()
    delegate.onDrawBox = { [weak self] corners in
      self?.drawBox(corners)
    }
    delegate.onDetectCard = { [weak self] title, setCode in
      self?.didDetectCard?(title, setCode)
    }
    self.captureDelegate = delegate
    
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(delegate, queue: videoDataOutputQueue)
    
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
    super.viewDidAppear(animated)
    videoDataOutputQueue.async { [weak self] in
      self?.captureSession.startRunning()
    }
  }
  
  private func drawBox(_ corners: VNRectangleObserver.Corners?) {
    boundingBoxLayer.path = nil
    guard let corners = corners else { return }
    
    let converted = [
      corners.topLeft,
      corners.topRight,
      corners.bottomRight,
      corners.bottomLeft
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
    converted.dropFirst().forEach { path.addLine(to: $0) }
    path.close()
    
    boundingBoxLayer.path = path.cgPath
  }
}

// MARK: - CaptureDelegate

private final class CaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
  var onDrawBox: (@Sendable (VNRectangleObserver.Corners?) -> Void)?
  var onDetectCard: (@Sendable (String, String) -> Void)?
  
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
    guard !isProcessing else { return }
    isProcessing = true
    
    defer { isProcessing = false }
    
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let sendableBuffer = SendableImageBuffer(imageBuffer)
    
    guard let observer = VNRectangleObserver(imageBuffer: imageBuffer) else { return }
    
    guard let corners = observer.process() else {
      DispatchQueue.main.async { [weak self] in self?.onDrawBox?(nil) }
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      self?.onDrawBox?(corners)
    }
    
    processOCR(
      on: extractAndFlattenCard(from: sendableBuffer.value, observation: corners)
    )
  }
  
  private func processOCR(on cardImage: CGImage?) {
    guard let cardImage else { return }
    
    let width = CGFloat(cardImage.width)
    let height = CGFloat(cardImage.height)
    
    let titleRect = CGRect(x: 0, y: 0, width: width, height: height * 0.15)
    let setRect = CGRect(x: 0, y: height * 0.92, width: width * 0.5, height: height * 0.08)
    
    guard
      let titleImg = cardImage.cropping(to: titleRect),
      let setImg = cardImage.cropping(to: setRect)
    else { return }
    
    let titleReq = VNRecognizeTextRequest()
    titleReq.recognitionLevel = .accurate
    
    let setReq = VNRecognizeTextRequest()
    setReq.recognitionLevel = .accurate
    
    try? VNImageRequestHandler(cgImage: titleImg, options: [:]).perform([titleReq])
    try? VNImageRequestHandler(cgImage: setImg, options: [:]).perform([setReq])
    
    let title = titleReq.results?.first?.topCandidates(1).first?.string ?? ""
    let setRaw = setReq.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
    let parsedSet = parseSet(setRaw)
    
    guard !title.isEmpty else { return }
    
    let callback = onDetectCard
    DispatchQueue.main.async {
      callback?(title, parsedSet.isEmpty ? setRaw.joined(separator: " ") : parsedSet)
    }
  }
  
  private func parseSet(_ strings: [String]) -> String {
    let words = strings.flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }
    var n = ""; var s = ""
    for word in words {
      let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
      let u = cleaned.uppercased()
      
      if n.isEmpty, u.range(of: "^\\d{3,4}$", options: .regularExpression) != nil {
        n = u
      } else if s.isEmpty, u.count == 3 {
        s = u
      }
    }
    return s.isEmpty ? "" : "\(s) #\(n)"
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
