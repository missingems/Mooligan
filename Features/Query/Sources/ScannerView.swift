import UIKit
import AVFoundation
import Vision
import CoreImage
import SwiftUI

// MARK: - SwiftUI Bridge
struct ScannerView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> ScannerViewController {
    return ScannerViewController()
  }
  
  func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
    // No updates needed as the camera runs its own internal loop
  }
}

// MARK: - Core Scanner Logic
class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
  
  private let captureSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated)
  private var isProcessingCard = false
  nonisolated private let ciContext = CIContext()
  
  private var currentTopLeft: CGPoint = .zero
  private var currentTopRight: CGPoint = .zero
  private var currentBottomLeft: CGPoint = .zero
  private var currentBottomRight: CGPoint = .zero
  
  private let boundingBoxLayer = CAShapeLayer()
  private let titlePreviewView = UIImageView()
  private let setCodePreviewView = UIImageView()
  private let titleLabel = UILabel()
  private let setCodeLabel = UILabel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    setupCamera()
    setupUI()
  }
  
  private func setupUI() {
    boundingBoxLayer.strokeColor = UIColor.green.cgColor
    boundingBoxLayer.lineWidth = 3.5
    boundingBoxLayer.fillColor = UIColor.green.withAlphaComponent(0.05).cgColor
    boundingBoxLayer.lineJoin = .round
    boundingBoxLayer.lineCap = .round
    boundingBoxLayer.shadowColor = UIColor.green.cgColor
    boundingBoxLayer.shadowOpacity = 0.9
    boundingBoxLayer.shadowRadius = 10
    view.layer.addSublayer(boundingBoxLayer)
    
    let overlayStack = UIStackView()
    overlayStack.axis = .vertical
    overlayStack.spacing = 8
    overlayStack.translatesAutoresizingMaskIntoConstraints = false
    overlayStack.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    overlayStack.layer.cornerRadius = 12
    overlayStack.isLayoutMarginsRelativeArrangement = true
    overlayStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
    
    let titleStack = UIStackView(arrangedSubviews: [titlePreviewView, titleLabel])
    titleStack.axis = .horizontal
    titleStack.spacing = 12
    titlePreviewView.widthAnchor.constraint(equalToConstant: 120).isActive = true
    titlePreviewView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    titleLabel.textColor = .white
    titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
    titleLabel.text = "Detecting..."
    
    let setCodeStack = UIStackView(arrangedSubviews: [setCodePreviewView, setCodeLabel])
    setCodeStack.axis = .horizontal
    setCodeStack.spacing = 12
    setCodePreviewView.widthAnchor.constraint(equalToConstant: 80).isActive = true
    setCodePreviewView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    setCodeLabel.textColor = .cyan
    setCodeLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
    setCodeLabel.text = "..."
    
    overlayStack.addArrangedSubview(titleStack)
    overlayStack.addArrangedSubview(setCodeStack)
    view.addSubview(overlayStack)
    
    NSLayoutConstraint.activate([
      overlayStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      overlayStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      overlayStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
    ])
  }
  
  private func setupCamera() {
    captureSession.sessionPreset = .hd1920x1080
    guard let backCamera = AVCaptureDevice.default(for: .video),
          let input = try? AVCaptureDeviceInput(device: backCamera) else { return }
    if captureSession.canAddInput(input) { captureSession.addInput(input) }
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    videoOutput.alwaysDiscardsLateVideoFrames = true
    if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = view.bounds
    view.layer.insertSublayer(previewLayer, at: 0)
    DispatchQueue.global(qos: .background).async { self.captureSession.startRunning() }
  }
  
  nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    
    let rawCI = CIImage(cvPixelBuffer: pixelBuffer)
    guard let filter = CIFilter(name: "CIColorControls") else { return }
    filter.setValue(rawCI, forKey: kCIInputImageKey)
    filter.setValue(2.2, forKey: kCIInputContrastKey)
    filter.setValue(-0.1, forKey: kCIInputBrightnessKey)
    guard let enhancedCI = filter.outputImage else { return }
    
    let request = VNDetectRectanglesRequest()
    request.maximumObservations = 1
    request.minimumConfidence = 0.6
    
    let handler = VNImageRequestHandler(ciImage: enhancedCI, orientation: .right, options: [:])
    
    do {
      try handler.perform([request])
      
      guard let observation = request.results?.first else {
        Task { @MainActor in self.boundingBoxLayer.path = nil }
        return
      }
      
      let tl = observation.topLeft; let tr = observation.topRight
      let bl = observation.bottomLeft; let br = observation.bottomRight
      
      Task { @MainActor in
        self.drawBoundingBox(topLeft: tl, topRight: tr, bottomLeft: bl, bottomRight: br)
      }
      
      guard let flattenedCGImage = extractAndFlattenCard(from: pixelBuffer, observation: observation) else { return }
      
      Task { @MainActor in
        guard !self.isProcessingCard else { return }
        self.isProcessingCard = true
        self.processCardData(flattenedCGImage: flattenedCGImage)
      }
    } catch {
      print(error)
    }
  }
  
  private func drawBoundingBox(topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) {
    func convertPoint(_ visionPoint: CGPoint) -> CGPoint {
      let sensorPoint = CGPoint(x: 1.0 - visionPoint.y, y: 1.0 - visionPoint.x)
      return previewLayer.layerPointConverted(fromCaptureDevicePoint: sensorPoint)
    }
    
    let targetTL = convertPoint(topLeft); let targetTR = convertPoint(topRight)
    let targetBL = convertPoint(bottomLeft); let targetBR = convertPoint(bottomRight)
    
    let factor: CGFloat = 0.25
    currentTopLeft = smoothPoint(from: currentTopLeft, to: targetTL, factor: factor)
    currentTopRight = smoothPoint(from: currentTopRight, to: targetTR, factor: factor)
    currentBottomLeft = smoothPoint(from: currentBottomLeft, to: targetBL, factor: factor)
    currentBottomRight = smoothPoint(from: currentBottomRight, to: targetBR, factor: factor)
    
    let path = UIBezierPath()
    let radius: CGFloat = 12.0
    
    func pointOnLine(start: CGPoint, end: CGPoint, distance: CGFloat) -> CGPoint {
      let totalDist = hypot(end.x - start.x, end.y - start.y)
      return CGPoint(x: start.x + (end.x - start.x) * (distance / totalDist), y: start.y + (end.y - start.y) * (distance / totalDist))
    }
    
    path.move(to: pointOnLine(start: currentTopLeft, end: currentTopRight, distance: radius))
    path.addLine(to: pointOnLine(start: currentTopRight, end: currentTopLeft, distance: radius))
    path.addQuadCurve(to: pointOnLine(start: currentTopRight, end: currentBottomRight, distance: radius), controlPoint: currentTopRight)
    path.addLine(to: pointOnLine(start: currentBottomRight, end: currentTopRight, distance: radius))
    path.addQuadCurve(to: pointOnLine(start: currentBottomRight, end: currentBottomLeft, distance: radius), controlPoint: currentBottomRight)
    path.addLine(to: pointOnLine(start: currentBottomLeft, end: currentBottomRight, distance: radius))
    path.addQuadCurve(to: pointOnLine(start: currentBottomLeft, end: currentTopLeft, distance: radius), controlPoint: currentBottomLeft)
    path.addLine(to: pointOnLine(start: currentTopLeft, end: currentBottomLeft, distance: radius))
    path.addQuadCurve(to: pointOnLine(start: currentTopLeft, end: currentTopRight, distance: radius), controlPoint: currentTopLeft)
    path.close()
    
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    boundingBoxLayer.path = path.cgPath
    CATransaction.commit()
  }
  
  private func smoothPoint(from: CGPoint, to: CGPoint, factor: CGFloat) -> CGPoint {
    if from == .zero { return to }
    return CGPoint(x: from.x + (to.x - from.x) * factor, y: from.y + (to.y - from.y) * factor)
  }
  
  private func processCardData(flattenedCGImage: CGImage) {
    let width = CGFloat(flattenedCGImage.width)
    let height = CGFloat(flattenedCGImage.height)
    
    let setCodeHeight = height * 0.1
    let titleRect = CGRect(x: 0, y: 0, width: width * 0.85, height: height * 0.14)
    let setCodeRect = CGRect(x: 0, y: height - setCodeHeight, width: width * 0.35, height: setCodeHeight)
    
    guard let rawTitleCGImage = flattenedCGImage.cropping(to: titleRect),
          let rawSetCodeCGImage = flattenedCGImage.cropping(to: setCodeRect) else {
      self.isProcessingCard = false
      return
    }
    
    // 👉 PRE-PROCESS BOTH IMAGES FOR OCR
    let processedTitleCGImage = preprocessForOCR(cgImage: rawTitleCGImage)
    let processedSetCodeCGImage = preprocessForOCR(cgImage: rawSetCodeCGImage)
    
    // Update the UI Previews to show the B&W/High-Contrast versions!
    self.titlePreviewView.image = UIImage(cgImage: processedTitleCGImage)
    self.setCodePreviewView.image = UIImage(cgImage: processedSetCodeCGImage)
    
    Task.detached { [weak self] in
      // Send the processed, clean images to Vision
      self?.performOCR(on: processedTitleCGImage, isTitle: true)
      self?.performOCR(on: processedSetCodeCGImage, isTitle: false)
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.isProcessingCard = false }
  }
  
  nonisolated private func preprocessForOCR(cgImage: CGImage) -> CGImage {
    let ciImage = CIImage(cgImage: cgImage)
    
    guard let filter = CIFilter(name: "CIColorControls") else { return cgImage }
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    
    // 1. Strip all color to make it grayscale
    filter.setValue(0.0, forKey: kCIInputSaturationKey)
    
    // 2. Boost the contrast so text pops against the background
    filter.setValue(1.8, forKey: kCIInputContrastKey)
    
    // 3. Slightly increase brightness to keep dark backgrounds from crushing the text
    filter.setValue(0.1, forKey: kCIInputBrightnessKey)
    
    guard let output = filter.outputImage,
          let processedCGImage = ciContext.createCGImage(output, from: output.extent) else {
      return cgImage // Fallback to original if filter fails
    }
    
    return processedCGImage
  }
  
  nonisolated private func extractAndFlattenCard(from pixelBuffer: CVPixelBuffer, observation: VNRectangleObservation) -> CGImage? {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
    let width = ciImage.extent.width; let height = ciImage.extent.height
    let tl = CIVector(x: observation.topLeft.x * width, y: observation.topLeft.y * height)
    let tr = CIVector(x: observation.topRight.x * width, y: observation.topRight.y * height)
    let bl = CIVector(x: observation.bottomLeft.x * width, y: observation.bottomLeft.y * height)
    let br = CIVector(x: observation.bottomRight.x * width, y: observation.bottomRight.y * height)
    
    guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(tl, forKey: "inputTopLeft"); filter.setValue(tr, forKey: "inputTopRight")
    filter.setValue(bl, forKey: "inputBottomLeft"); filter.setValue(br, forKey: "inputBottomRight")
    
    guard let output = filter.outputImage else { return nil }
    return ciContext.createCGImage(output, from: output.extent)
  }
  
  nonisolated private func performOCR(on cgImage: CGImage, isTitle: Bool) {
    let request = VNRecognizeTextRequest { [weak self] request, _ in
      guard let self, let obs = request.results as? [VNRecognizedTextObservation] else { return }
      let strings = obs.compactMap { $0.topCandidates(1).first?.string }
      
      Task { @MainActor in
        if isTitle { self.titleLabel.text = strings.first ?? "..." }
        else {
          let result = self.parseSetAndNumber(from: strings)
          if let n = result.number, let s = result.set {
            self.setCodeLabel.text = "\(s) — #\(n)"
          }
        }
      }
    }
    request.recognitionLevel = isTitle ? .accurate : .fast
    request.usesLanguageCorrection = false
    try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
  }
  
  private func parseSetAndNumber(from strings: [String]) -> (number: String?, set: String?) {
    var n: String?; var s: String?
    let words = strings.flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    let ignore = ["EN", "JP", "USA", "MADE", "COPY", "ILLUS"]
    
    for word in words {
      let u = word.uppercased()
      let cleanedNum = u.replacingOccurrences(of: "^[A-Z]+", with: "", options: .regularExpression)
      if n == nil, cleanedNum.range(of: "^\\d{3,4}$", options: .regularExpression) != nil { n = cleanedNum }
      else if s == nil, u.count == 3, !ignore.contains(u) { s = u }
    }
    return (n, s)
  }
}
