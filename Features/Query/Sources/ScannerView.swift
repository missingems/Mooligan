import UIKit
import AVFoundation
import Vision
import CoreImage

class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
  
  // MARK: - Properties
  private let captureSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private let boundingBoxLayer = CAShapeLayer()
  private var rectangleRequest: VNDetectRectanglesRequest!
  
  // Core Image context for high-performance image flattening
  private let ciContext = CIContext()
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupBoundingBox()
    setupVision()
    setupCamera()
  }
  
  // MARK: - Setup
  private func setupBoundingBox() {
    boundingBoxLayer.strokeColor = UIColor.green.cgColor
    boundingBoxLayer.lineWidth = 4.0
    boundingBoxLayer.fillColor = UIColor.clear.cgColor
    view.layer.addSublayer(boundingBoxLayer)
  }
  
  private func setupVision() {
    rectangleRequest = VNDetectRectanglesRequest(completionHandler: handleRectangles)
    rectangleRequest.maximumObservations = 1
    rectangleRequest.minimumConfidence = 0.8
    rectangleRequest.minimumAspectRatio = 0.6
    rectangleRequest.maximumAspectRatio = 0.8
  }
  
  private func setupCamera() {
    captureSession.sessionPreset = .hd1920x1080
    
    guard let backCamera = AVCaptureDevice.default(for: .video),
          let input = try? AVCaptureDeviceInput(device: backCamera) else { return }
    
    if captureSession.canAddInput(input) { captureSession.addInput(input) }
    
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
    videoOutput.alwaysDiscardsLateVideoFrames = true
    
    if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = view.bounds
    view.layer.insertSublayer(previewLayer, at: 0)
    
    DispatchQueue.global(qos: .background).async {
      self.captureSession.startRunning()
    }
  }
  
  // MARK: - Camera Feed Delegate
  nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    
    // Portrait orientation is technically .right for the raw camera buffer
    let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
    try? requestHandler.perform([rectangleRequest])
    
    // If we found a card, extract it!
    if let results = rectangleRequest.results as? [VNRectangleObservation], let card = results.first {
      extractAndFlattenCard(from: pixelBuffer, observation: card)
    }
  }
  
  // MARK: - Vision Handling & UI
  private func handleRectangles(request: VNRequest, error: Error?) {
    guard let observations = request.results as? [VNRectangleObservation],
          let cardObservation = observations.first else {
      
      // 1. VISION LOST THE CARD: Fade out gently instead of an instant flash
      DispatchQueue.main.async { self.hideBoundingBoxGently() }
      return
    }
    
    // 2. VISION FOUND THE CARD: Draw and morph the box
    DispatchQueue.main.async {
      self.drawBoundingBox(for: cardObservation)
    }
  }
  
  private func hideBoundingBoxGently() {
    // Only trigger the fade if it's currently visible
    guard boundingBoxLayer.opacity == 1.0 else { return }
    
    let fadeOut = CABasicAnimation(keyPath: "opacity")
    fadeOut.fromValue = 1.0
    fadeOut.toValue = 0.0
    fadeOut.duration = 0.2 // A gentle 0.2 second fade
    
    boundingBoxLayer.add(fadeOut, forKey: "opacityFade")
    boundingBoxLayer.opacity = 0.0
  }
  
  private func drawBoundingBox(for observation: VNRectangleObservation) {
    func convertPoint(_ visionPoint: CGPoint) -> CGPoint {
      let sensorPoint = CGPoint(x: 1.0 - visionPoint.y, y: 1.0 - visionPoint.x)
      return previewLayer.layerPointConverted(fromCaptureDevicePoint: sensorPoint)
    }
    
    let path = UIBezierPath()
    path.move(to: convertPoint(observation.topLeft))
    path.addLine(to: convertPoint(observation.topRight))
    path.addLine(to: convertPoint(observation.bottomRight))
    path.addLine(to: convertPoint(observation.bottomLeft))
    path.close()
    
    // --- THE MAGIC: MORPHING ANIMATION ---
    let morphAnimation = CABasicAnimation(keyPath: "path")
    // Start the morph from exactly what the layer currently looks like on-screen
    morphAnimation.fromValue = boundingBoxLayer.presentation()?.path ?? boundingBoxLayer.path
    morphAnimation.toValue = path.cgPath
    morphAnimation.duration = 0.1 // 0.1 seconds creates a liquid, smooth morph
    morphAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    
    boundingBoxLayer.add(morphAnimation, forKey: "pathMorph")
    boundingBoxLayer.path = path.cgPath
    
    // --- FADE IN ---
    // If the box was hidden, gently fade it back in while it morphs
    if boundingBoxLayer.opacity == 0.0 {
      let fadeIn = CABasicAnimation(keyPath: "opacity")
      fadeIn.fromValue = 0.0
      fadeIn.toValue = 1.0
      fadeIn.duration = 0.15
      
      boundingBoxLayer.add(fadeIn, forKey: "opacityFade")
      boundingBoxLayer.opacity = 1.0
    }
  }
  
  // MARK: - Perspective Warp (The Magic)
  private func extractAndFlattenCard(from pixelBuffer: CVPixelBuffer, observation: VNRectangleObservation) {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
    
    let imageWidth = ciImage.extent.width
    let imageHeight = ciImage.extent.height
    
    // 2. Core Image and Vision both use a bottom-left origin!
    // We just multiply the normalized points (0.0 to 1.0) by the actual image dimensions.
    let topLeft = CGPoint(x: observation.topLeft.x * imageWidth, y: observation.topLeft.y * imageHeight)
    let topRight = CGPoint(x: observation.topRight.x * imageWidth, y: observation.topRight.y * imageHeight)
    let bottomLeft = CGPoint(x: observation.bottomLeft.x * imageWidth, y: observation.bottomLeft.y * imageHeight)
    let bottomRight = CGPoint(x: observation.bottomRight.x * imageWidth, y: observation.bottomRight.y * imageHeight)
    
    // 3. Apply the Perspective Correction Filter
    let filter = CIFilter(name: "CIPerspectiveCorrection")!
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
    filter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
    filter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
    filter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
    
    guard let outputImage = filter.outputImage,
          let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else { return }
    
    let flatCardImage = UIImage(cgImage: cgImage)
    
    // --> flatCardImage is now a perfect, un-skewed rectangle of the card! <--
    // print("Extracted flat card image: \(flatCardImage.size)")
  }
}

import SwiftUI

struct ScannerView: UIViewControllerRepresentable {
  
  // Create the initial instance of our UIKit controller
  func makeUIViewController(context: Context) -> ScannerViewController {
    return ScannerViewController()
  }
  
  // This fires if SwiftUI state changes and we need to update the UIKit side.
  // We can leave it empty for now since the camera runs independently.
  func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
    
  }
}
