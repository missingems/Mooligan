import UIKit
import Vision
@preconcurrency import AVFoundation
import CoreImage

final class OCRViewController: UIViewController {
  private let minimumCornerLength: CGFloat = 18
  private let maximumCornerLength: CGFloat = 36
  
  let gatekeeper = ScannerGatekeeper()
  
  var isScanningPaused = false {
    didSet {
      guard isScanningPaused != oldValue else { return }
      gatekeeper.isPaused = isScanningPaused
      captureDelegate.isOCRDisabled = isScanningPaused
    }
  }
  
  var isProcessingFrame = false {
    didSet {
      guard isProcessingFrame != oldValue else { return }
      gatekeeper.isProcessing = isProcessingFrame
    }
  }
  
  var isTrackingPaused = false {
    didSet {
      guard isTrackingPaused != oldValue else { return }
      captureDelegate.isTrackingDisabled = isTrackingPaused
      
      if isTrackingPaused {
        DispatchQueue.main.async { [weak self] in
          self?.transitionToFullDim()
        }
      } else {
        DispatchQueue.main.async { [weak self] in
          self?.executeFadeOut()
        }
      }
    }
  }
  
  var didDetectResult: ((ScannedImage) -> Void)?
  var didUpdateTrackingCorners: ((QuadCorners?) -> Void)?
  
  private let captureSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated)
  private let captureDelegate = OCRCaptureDelegate()
  private let sessionQueue = DispatchQueue(label: "CaptureSessionQueue")
  
  private let dimmingLayer = CAShapeLayer()
  private let shadowCornerLayer = CAShapeLayer()
  private let yellowCornerLayer = CAShapeLayer()
  private let solidDimLayer = CALayer()
  
  private let fadeOutDelay: TimeInterval = 0.6
  private let fadeOutDuration: TimeInterval = 0.35
  private let snapDuration: TimeInterval = 0.315
  
  private var fadeOutWorkItem: DispatchWorkItem?
  private var isOverlayVisible = false
  
  private var lastFocusTime: Date = .distantPast
  private let focusThrottleInterval: TimeInterval = 1.5
  
#if targetEnvironment(simulator)
  private var simulatorImageView: UIImageView!
  private var simulatorTimer: Timer?
  private var simulatorVisionObservation: VNRectangleObservation?
  private let ciContext = CIContext(options: [.cacheIntermediates: false])
#endif
  
  override func viewDidLoad() {
    super.viewDidLoad()
    captureDelegate.gatekeeper = gatekeeper
    setupCamera()
    setupOverlayLayers()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.bounds
    solidDimLayer.frame = view.bounds
    
#if targetEnvironment(simulator)
    simulatorImageView?.frame = view.bounds
#endif
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
#if targetEnvironment(simulator)
    startSimulatorLoop()
#else
    sessionQueue.async { [captureSession] in
      captureSession.startRunning()
    }
#endif
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
#if targetEnvironment(simulator)
    simulatorTimer?.invalidate()
    simulatorTimer = nil
#else
    sessionQueue.async { [captureSession] in
      captureSession.stopRunning()
    }
#endif
    fadeOutWorkItem?.cancel()
  }
}

// MARK: - Camera Setup
extension OCRViewController {
  private func setupCamera() {
#if targetEnvironment(simulator)
    setupSimulatorEnvironment()
    return
#endif
    
    guard
      let backCamera = AVCaptureDevice.default(for: .video),
      let input = try? AVCaptureDeviceInput(device: backCamera)
    else { return }
    
    captureSession.sessionPreset = .hd4K3840x2160
    
    if captureSession.canAddInput(input) {
      captureSession.addInput(input)
    }
    
    captureDelegate.onDrawBox = { [weak self] corners in
      self?.handleCorners(corners)
    }
    
    captureDelegate.onDetectCard = { [weak self] image, corners in
      guard let self, !self.isScanningPaused else { return }
      
      let points = self.convertToScreenPoints(corners)
      let minX = points.map(\.x).min() ?? 0
      let maxX = points.map(\.x).max() ?? 0
      let minY = points.map(\.y).min() ?? 0
      let maxY = points.map(\.y).max() ?? 0
      let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
      
      self.didDetectResult?(ScannedImage(value: image, bounds: rect))
    }
    
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(captureDelegate, queue: videoDataOutputQueue)
    if captureSession.canAddOutput(videoOutput) {
      captureSession.addOutput(videoOutput)
    }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = .resizeAspectFill
    view.layer.insertSublayer(previewLayer, at: 0)
  }
  
  private func setupOverlayLayers() {
    solidDimLayer.backgroundColor = UIColor.black.cgColor
    solidDimLayer.opacity = 0
    
    dimmingLayer.fillColor = UIColor.clear.cgColor
    dimmingLayer.shadowColor = UIColor.black.cgColor
    dimmingLayer.shadowRadius = 35
    dimmingLayer.shadowOpacity = 0.45
    dimmingLayer.shadowOffset = .zero
    dimmingLayer.opacity = 0
    
    shadowCornerLayer.strokeColor = UIColor.black.withAlphaComponent(0.55).cgColor
    shadowCornerLayer.lineWidth = 5.5
    shadowCornerLayer.fillColor = UIColor.clear.cgColor
    shadowCornerLayer.lineCap = .round
    shadowCornerLayer.lineJoin = .round
    shadowCornerLayer.opacity = 0
    
    yellowCornerLayer.strokeColor = UIColor.systemYellow.cgColor
    yellowCornerLayer.lineWidth = 4.5
    yellowCornerLayer.fillColor = UIColor.clear.cgColor
    yellowCornerLayer.lineCap = .round
    yellowCornerLayer.lineJoin = .round
    yellowCornerLayer.opacity = 0
    
    view.layer.addSublayer(solidDimLayer)
    view.layer.addSublayer(dimmingLayer)
    view.layer.addSublayer(shadowCornerLayer)
    view.layer.addSublayer(yellowCornerLayer)
  }
}

// MARK: - Simulator Mock
#if targetEnvironment(simulator)
extension OCRViewController {
  private func setupSimulatorEnvironment() {
    let mockImage = DesignComponentsAsset.simulatorCard.image
    
    simulatorImageView = UIImageView(image: mockImage)
    simulatorImageView.contentMode = .scaleAspectFill
    simulatorImageView.frame = view.bounds
    
    view.insertSubview(simulatorImageView, at: 0)
    runSimulatorVision(on: mockImage)
  }
  
  private func runSimulatorVision(on image: UIImage) {
    guard let cgImage = image.cgImage else { return }
    let request = VNDetectRectanglesRequest { [weak self] req, _ in
      self?.simulatorVisionObservation = req.results?.first as? VNRectangleObservation
    }
    request.minimumSize = 0.2
    request.maximumObservations = 1
    request.minimumConfidence = 0.5
    
    try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
  }
  
  private func startSimulatorLoop() {
    simulatorTimer?.invalidate()
    simulatorTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
      self?.simulateScanTick()
    }
  }
  
  private func simulateScanTick() {
    guard !self.isTrackingPaused else { return }
    guard let image = simulatorImageView.image else { return }
    
    guard let observation = simulatorVisionObservation else {
      self.didUpdateTrackingCorners?(nil)
      self.scheduleFadeOut()
      return
    }
    
    let viewSize = self.view.bounds.size
    let imageSize = image.size
    let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
    let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    let offsetX = (viewSize.width - scaledImageSize.width) / 2.0
    let offsetY = (viewSize.height - scaledImageSize.height) / 2.0
    
    func convertToViewSpace(_ point: CGPoint) -> CGPoint {
      let x = point.x * scaledImageSize.width + offsetX
      let y = (1.0 - point.y) * scaledImageSize.height + offsetY
      return CGPoint(x: x, y: y)
    }
    
    let rawPoints = [
      convertToViewSpace(observation.topLeft),
      convertToViewSpace(observation.topRight),
      convertToViewSpace(observation.bottomRight),
      convertToViewSpace(observation.bottomLeft)
    ]
    
    let points = Self.sortedCorners(rawPoints)
    
    let quad = QuadCorners(
      topLeft: points[0],
      topRight: points[1],
      bottomRight: points[2],
      bottomLeft: points[3]
    )
    
    guard self.isMagicTheGatheringRatio(points) else {
      self.didUpdateTrackingCorners?(nil)
      self.scheduleFadeOut()
      return
    }
    
    self.didUpdateTrackingCorners?(quad)
    
    guard self.gatekeeper.checkAndLockForProcessing() else { return }
    
    self.cancelFadeOut()
    
    let newDimmingPath = self.buildDimmingPath(for: points)
    let newCornerPath = self.buildCornersPath(for: points)
    
    if self.isOverlayVisible {
      self.snapPath(dimming: newDimmingPath, corners: newCornerPath)
    } else {
      self.setPath(dimming: newDimmingPath, corners: newCornerPath)
      self.fadeIn()
    }
    
    guard let ciImage = CIImage(image: image) else { return }
    let imgSize = ciImage.extent.size
    
    let filter = CIFilter(name: "CIPerspectiveCorrection")
    filter?.setValue(ciImage, forKey: kCIInputImageKey)
    filter?.setValue(CIVector(cgPoint: CGPoint(x: observation.topLeft.x * imgSize.width, y: observation.topLeft.y * imgSize.height)), forKey: "inputTopLeft")
    filter?.setValue(CIVector(cgPoint: CGPoint(x: observation.topRight.x * imgSize.width, y: observation.topRight.y * imgSize.height)), forKey: "inputTopRight")
    filter?.setValue(CIVector(cgPoint: CGPoint(x: observation.bottomLeft.x * imgSize.width, y: observation.bottomLeft.y * imgSize.height)), forKey: "inputBottomLeft")
    filter?.setValue(CIVector(cgPoint: CGPoint(x: observation.bottomRight.x * imgSize.width, y: observation.bottomRight.y * imgSize.height)), forKey: "inputBottomRight")
    
    guard let output = filter?.outputImage,
          let croppedCGImage = ciContext.createCGImage(output, from: output.extent) else {
      return
    }
    
    let minX = points.map(\.x).min() ?? 0
    let maxX = points.map(\.x).max() ?? 0
    let minY = points.map(\.y).min() ?? 0
    let maxY = points.map(\.y).max() ?? 0
    let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    
    self.didDetectResult?(ScannedImage(value: croppedCGImage, bounds: rect))
  }
}
#endif // targetEnvironment(simulator)

// MARK: - Corner Handling
extension OCRViewController {
  private func handleCorners(_ corners: VNRectangleObserver.Corners?) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      guard !self.isTrackingPaused else { return }
      
      guard let corners else {
        self.scheduleFadeOut()
        return
      }
      
      let points = self.convertToScreenPoints(corners)
      
      let quad = QuadCorners(
        topLeft: points[0],
        topRight: points[1],
        bottomRight: points[2],
        bottomLeft: points[3]
      )
      
      guard self.isMagicTheGatheringRatio(points) else {
        self.scheduleFadeOut()
        return
      }
      
      self.didUpdateTrackingCorners?(quad)
      self.focusCamera(on: points)
      self.cancelFadeOut()
      
      let newDimmingPath = self.buildDimmingPath(for: points)
      let newCornerPath = self.buildCornersPath(for: points)
      
      if self.isOverlayVisible {
        self.snapPath(dimming: newDimmingPath, corners: newCornerPath)
      } else {
        self.setPath(dimming: newDimmingPath, corners: newCornerPath)
        self.fadeIn()
      }
    }
  }
  
  private func focusCamera(on screenPoints: [CGPoint]) {
    let now = Date()
    guard now.timeIntervalSince(lastFocusTime) > focusThrottleInterval else { return }
    
    let centerX = screenPoints.map(\.x).reduce(0, +) / 4
    let centerY = screenPoints.map(\.y).reduce(0, +) / 4
    let screenCenter = CGPoint(x: centerX, y: centerY)
    
    let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: screenCenter)
    guard let device = AVCaptureDevice.default(for: .video) else { return }
    
    try? device.lockForConfiguration()
    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.continuousAutoFocus) {
      device.focusPointOfInterest = devicePoint
      device.focusMode = .continuousAutoFocus
    }
    if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
      device.exposurePointOfInterest = devicePoint
      device.exposureMode = .continuousAutoExposure
    }
    device.unlockForConfiguration()
    lastFocusTime = now
  }
  
  private func convertToScreenPoints(_ corners: VNRectangleObserver.Corners) -> [CGPoint] {
    let rawPoints = [corners.topLeft, corners.topRight, corners.bottomRight, corners.bottomLeft]
      .map { point in
        previewLayer.layerPointConverted(
          fromCaptureDevicePoint: CGPoint(x: 1.0 - point.y, y: 1.0 - point.x)
        )
      }
    return Self.sortedCorners(rawPoints)
  }
  
  private static func sortedCorners(_ points: [CGPoint]) -> [CGPoint] {
    guard points.count == 4 else { return points }
    
    let centerX = points.map(\.x).reduce(0, +) / 4
    let centerY = points.map(\.y).reduce(0, +) / 4
    
    var topLeft: CGPoint?, topRight: CGPoint?, bottomLeft: CGPoint?, bottomRight: CGPoint?
    
    for point in points {
      if point.x <= centerX && point.y <= centerY {
        topLeft = bestCandidate(topLeft, point, centerX, centerY)
      } else if point.x > centerX && point.y <= centerY {
        topRight = bestCandidate(topRight, point, centerX, centerY)
      } else if point.x <= centerX && point.y > centerY {
        bottomLeft = bestCandidate(bottomLeft, point, centerX, centerY)
      } else {
        bottomRight = bestCandidate(bottomRight, point, centerX, centerY)
      }
    }
    
    if topLeft == nil || topRight == nil || bottomLeft == nil || bottomRight == nil {
      let sorted = points.sorted {
        atan2($0.y - centerY, $0.x - centerX) < atan2($1.y - centerY, $1.x - centerX)
      }
      return [sorted[3], sorted[0], sorted[1], sorted[2]]
    }
    
    return [topLeft!, topRight!, bottomRight!, bottomLeft!]
  }
  
  private static func bestCandidate(_ current: CGPoint?, _ newPoint: CGPoint, _ centerX: CGFloat, _ centerY: CGFloat) -> CGPoint {
    guard let current else { return newPoint }
    return hypot(newPoint.x - centerX, newPoint.y - centerY) < hypot(current.x - centerX, current.y - centerY) ? newPoint : current
  }
}

// MARK: - Paths
extension OCRViewController {
  private func buildDimmingPath(for points: [CGPoint]) -> CGPath {
    let path = UIBezierPath(rect: view.bounds.insetBy(dx: -200, dy: -200))
    guard points.count == 4 else { return path.cgPath }
    
    let centerX = points.reduce(0) { $0 + $1.x } / 4
    let centerY = points.reduce(0) { $0 + $1.y } / 4
    let expansion: CGFloat = 16.0
    
    let expandedPoints = points.map { pt -> CGPoint in
      let dx = pt.x - centerX
      let dy = pt.y - centerY
      let dist = hypot(dx, dy)
      guard dist > 0 else { return pt }
      return CGPoint(x: pt.x + (dx / dist) * expansion, y: pt.y + (dy / dist) * expansion)
    }
    
    let cutoutPath = UIBezierPath()
    cutoutPath.move(to: expandedPoints[0])
    cutoutPath.addLine(to: expandedPoints[1])
    cutoutPath.addLine(to: expandedPoints[2])
    cutoutPath.addLine(to: expandedPoints[3])
    cutoutPath.close()
    
    path.append(cutoutPath.reversing())
    return path.cgPath
  }
  
  private func buildCornersPath(for points: [CGPoint]) -> CGPath {
    guard points.count == 4 else { return CGMutablePath() }
    
    let topLeft = points[0], topRight = points[1], bottomRight = points[2], bottomLeft = points[3]
    
    let topEdge  = hypot(topRight.x - topLeft.x, topRight.y - topLeft.y)
    let leftEdge = hypot(bottomLeft.x - topLeft.x, bottomLeft.y - topLeft.y)
    let isLandscape = topEdge > leftEdge
    let shortEdge = isLandscape ? leftEdge : topEdge
    
    let cornerRadius = 0.048 * shortEdge
    let armLength = min(maximumCornerLength, max(minimumCornerLength, cornerRadius * 3 + 8))
    
    let path = UIBezierPath()
    addCorner(to: path, at: topLeft, edge1End: topRight, edge2End: bottomLeft, armLength: armLength, cornerRadius: cornerRadius)
    addCorner(to: path, at: topRight, edge1End: topLeft, edge2End: bottomRight, armLength: armLength, cornerRadius: cornerRadius)
    addCorner(to: path, at: bottomRight, edge1End: bottomLeft, edge2End: topRight, armLength: armLength, cornerRadius: cornerRadius)
    addCorner(to: path, at: bottomLeft, edge1End: bottomRight, edge2End: topLeft, armLength: armLength, cornerRadius: cornerRadius)
    return path.cgPath
  }
  
  private func addCorner(
    to path: UIBezierPath,
    at corner: CGPoint,
    edge1End: CGPoint,
    edge2End: CGPoint,
    armLength: CGFloat,
    cornerRadius: CGFloat
  ) {
    let direction1 = unitVector(from: corner, to: edge1End)
    let direction2 = unitVector(from: corner, to: edge2End)
    
    let tip1 = CGPoint(x: corner.x + direction1.x * armLength, y: corner.y + direction1.y * armLength)
    let tip2 = CGPoint(x: corner.x + direction2.x * armLength, y: corner.y + direction2.y * armLength)
    
    let curveStart = CGPoint(x: corner.x + direction1.x * cornerRadius, y: corner.y + direction1.y * cornerRadius)
    let curveEnd   = CGPoint(x: corner.x + direction2.x * cornerRadius, y: corner.y + direction2.y * cornerRadius)
    
    let kappa: CGFloat = 0.55228
    
    let controlPoint1 = CGPoint(x: curveStart.x - direction1.x * cornerRadius * kappa,
                                y: curveStart.y - direction1.y * cornerRadius * kappa)
    let controlPoint2 = CGPoint(x: curveEnd.x - direction2.x * cornerRadius * kappa,
                                y: curveEnd.y - direction2.y * cornerRadius * kappa)
    
    path.move(to: tip1)
    path.addLine(to: curveStart)
    path.addCurve(to: curveEnd, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    path.addLine(to: tip2)
  }
  
  private func unitVector(from startPoint: CGPoint, to endPoint: CGPoint) -> CGPoint {
    let deltaX = endPoint.x - startPoint.x, deltaY = endPoint.y - startPoint.y
    let length = hypot(deltaX, deltaY)
    guard length > 0 else { return .zero }
    return CGPoint(x: deltaX / length, y: deltaY / length)
  }
}

// MARK: - Layer Animations
extension OCRViewController {
  private func setPath(dimming: CGPath, corners: CGPath) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    dimmingLayer.shadowPath = dimming
    shadowCornerLayer.path = corners
    yellowCornerLayer.path = corners
    CATransaction.commit()
  }
  
  private func snapPath(dimming newDimmingPath: CGPath, corners newCornersPath: CGPath) {
    func makeAnimation(keyPath: String, from path: CGPath?, to newPath: CGPath) -> CABasicAnimation {
      let animation = CABasicAnimation(keyPath: keyPath)
      animation.fromValue = path
      animation.toValue = newPath
      animation.duration = snapDuration
      animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
      animation.fillMode = .forwards
      animation.isRemovedOnCompletion = false
      return animation
    }
    
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    
    let currentShadowPath = dimmingLayer.presentation()?.shadowPath ?? dimmingLayer.shadowPath
    let currentShadowCorners = shadowCornerLayer.presentation()?.path ?? shadowCornerLayer.path
    let currentYellowCorners = yellowCornerLayer.presentation()?.path ?? yellowCornerLayer.path
    
    dimmingLayer.shadowPath = newDimmingPath
    shadowCornerLayer.path = newCornersPath
    yellowCornerLayer.path = newCornersPath
    CATransaction.commit()
    
    dimmingLayer.add(makeAnimation(keyPath: "shadowPath", from: currentShadowPath, to: newDimmingPath), forKey: "snapShadow")
    shadowCornerLayer.add(makeAnimation(keyPath: "path", from: currentShadowCorners, to: newCornersPath), forKey: "snapCorners")
    yellowCornerLayer.add(makeAnimation(keyPath: "path", from: currentYellowCorners, to: newCornersPath), forKey: "snapCorners")
  }
  
  private func fadeIn() {
    isOverlayVisible = true
    let animation = opacityAnimation(from: 0, to: 1.0, duration: 0.2)
    dimmingLayer.opacity = 1
    shadowCornerLayer.opacity = 1
    yellowCornerLayer.opacity = 1
    dimmingLayer.add(animation, forKey: "fadeIn")
    shadowCornerLayer.add(animation.copy() as! CABasicAnimation, forKey: "fadeIn")
    yellowCornerLayer.add(animation.copy() as! CABasicAnimation, forKey: "fadeIn")
  }
  
  fileprivate func scheduleFadeOut() {
    guard isOverlayVisible, fadeOutWorkItem == nil else { return }
    let workItem = DispatchWorkItem { [weak self] in
      self?.executeFadeOut()
      self?.fadeOutWorkItem = nil
    }
    fadeOutWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDelay, execute: workItem)
  }
  
  fileprivate func cancelFadeOut() {
    fadeOutWorkItem?.cancel()
    fadeOutWorkItem = nil
    guard isOverlayVisible else { return }
    
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    dimmingLayer.opacity = 1
    shadowCornerLayer.opacity = 1
    yellowCornerLayer.opacity = 1
    CATransaction.commit()
    
    dimmingLayer.removeAnimation(forKey: "fadeOut")
    shadowCornerLayer.removeAnimation(forKey: "fadeOutBorder")
    yellowCornerLayer.removeAnimation(forKey: "fadeOutBorder")
  }
  
  fileprivate func executeFadeOut() {
    isOverlayVisible = false
    let animation = opacityAnimation(from: 1.0, to: 0, duration: fadeOutDuration)
    animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
    
    let currentSolid = solidDimLayer.presentation()?.opacity ?? solidDimLayer.opacity
    let solidAnimation = opacityAnimation(from: currentSolid, to: 0, duration: fadeOutDuration)
    solidAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
    
    CATransaction.begin()
    CATransaction.setCompletionBlock { [weak self] in
      guard let self, !self.isOverlayVisible else { return }
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      self.dimmingLayer.shadowPath = nil
      self.shadowCornerLayer.path = nil
      self.yellowCornerLayer.path = nil
      CATransaction.commit()
    }
    
    dimmingLayer.opacity = 0
    shadowCornerLayer.opacity = 0
    yellowCornerLayer.opacity = 0
    solidDimLayer.opacity = 0
    
    dimmingLayer.add(animation, forKey: "fadeOut")
    shadowCornerLayer.add(animation.copy() as! CABasicAnimation, forKey: "fadeOutBorder")
    yellowCornerLayer.add(animation.copy() as! CABasicAnimation, forKey: "fadeOutBorder")
    solidDimLayer.add(solidAnimation, forKey: "fadeOutSolid")
    
    CATransaction.commit()
  }
  
  fileprivate func transitionToFullDim() {
    cancelFadeOut()
    isOverlayVisible = true
    
    let currentDimOpacity = dimmingLayer.presentation()?.opacity ?? dimmingLayer.opacity
    let currentBorderOpacity = yellowCornerLayer.presentation()?.opacity ?? yellowCornerLayer.opacity
    
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    dimmingLayer.opacity = 0
    shadowCornerLayer.opacity = 0
    yellowCornerLayer.opacity = 0
    solidDimLayer.opacity = 0.45
    CATransaction.commit()
    
    let dimmingFadeOut = CABasicAnimation(keyPath: "opacity")
    dimmingFadeOut.fromValue = currentDimOpacity
    dimmingFadeOut.toValue = 0.0
    dimmingFadeOut.duration = 0.35
    dimmingFadeOut.fillMode = .forwards
    dimmingFadeOut.isRemovedOnCompletion = false
    
    let borderFadeOut = CABasicAnimation(keyPath: "opacity")
    borderFadeOut.fromValue = currentBorderOpacity
    borderFadeOut.toValue = 0.0
    borderFadeOut.duration = 0.35
    borderFadeOut.fillMode = .forwards
    borderFadeOut.isRemovedOnCompletion = false
    
    let solidFadeIn = CABasicAnimation(keyPath: "opacity")
    solidFadeIn.fromValue = 0.0
    solidFadeIn.toValue = 0.45
    solidFadeIn.duration = 0.35
    solidFadeIn.fillMode = .forwards
    solidFadeIn.isRemovedOnCompletion = false
    
    dimmingLayer.add(dimmingFadeOut, forKey: "fadeOutDim")
    shadowCornerLayer.add(borderFadeOut, forKey: "fadeOutBorder")
    yellowCornerLayer.add(borderFadeOut, forKey: "fadeOutBorder")
    solidDimLayer.add(solidFadeIn, forKey: "fadeInSolid")
  }
  
  private func opacityAnimation(from startValue: Float, to endValue: Float, duration: TimeInterval) -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.fromValue = startValue
    animation.toValue = endValue
    animation.duration = duration
    animation.fillMode = .forwards
    animation.isRemovedOnCompletion = false
    return animation
  }
  
  fileprivate func isMagicTheGatheringRatio(_ points: [CGPoint]) -> Bool {
    guard points.count == 4 else { return false }
    let topLeft = points[0], topRight = points[1], bottomRight = points[2], bottomLeft = points[3]
    
    let topWidth = hypot(topRight.x - topLeft.x, topRight.y - topLeft.y)
    let bottomWidth = hypot(bottomRight.x - bottomLeft.x, bottomRight.y - bottomLeft.y)
    let leftHeight = hypot(bottomLeft.x - topLeft.x, bottomLeft.y - topLeft.y)
    let rightHeight = hypot(bottomRight.x - topRight.x, bottomRight.y - topRight.y)
    
    let averageWidth = (topWidth + bottomWidth) / 2.0
    let averageHeight = (leftHeight + rightHeight) / 2.0
    guard averageWidth > 0, averageHeight > 0 else { return false }
    
    let ratio = max(averageWidth, averageHeight) / min(averageWidth, averageHeight)
    let targetRatio: CGFloat = 88.0 / 63.0
    let tolerance: CGFloat = 0.15
    return abs(ratio - targetRatio) <= tolerance
  }
}
