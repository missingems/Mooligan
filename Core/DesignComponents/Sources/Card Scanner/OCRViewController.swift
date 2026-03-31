import UIKit
import Vision
@preconcurrency import AVFoundation

final class OCRViewController: UIViewController {
  var didDetectResult: ((OCRCardScannedResult) -> Void)?
  
  private let captureSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated)
  private let captureDelegate = OCRCaptureDelegate()
  private let sessionQueue = DispatchQueue(label: "CaptureSessionQueue")
  
  private let shadowCornerLayer = CAShapeLayer()
  private let whiteCornerLayer = CAShapeLayer()
  
  private let fadeOutDelay: TimeInterval = 0.6
  private let fadeOutDuration: TimeInterval = 0.35
  private let snapDuration: TimeInterval = 0.12
  
  private let minimumCornerLength: CGFloat = 18
  private let maximumCornerLength: CGFloat = 36
  
  private var fadeOutWorkItem: DispatchWorkItem?
  private var isOverlayVisible = false
  private var hasConfirmedCard = false
  
  private var lastFocusTime: Date = .distantPast
  private let focusThrottleInterval: TimeInterval = 1.5
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupCamera()
    setupOverlayLayers()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    sessionQueue.async { [captureSession] in
      captureSession.startRunning()
    }
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    sessionQueue.async { [captureSession] in
      captureSession.stopRunning()
    }
    fadeOutWorkItem?.cancel()
  }
}

// MARK: - Setup
extension OCRViewController {
  private func setupCamera() {
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
    
    captureDelegate.onDetectCard = { [weak self] result in
      guard let self else { return }
      let isComplete = !result.title.isEmpty
      DispatchQueue.main.async {
        self.hasConfirmedCard = isComplete
      }
      if isComplete {
        self.didDetectResult?(result)
      }
    }
    
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(captureDelegate, queue: videoDataOutputQueue)
    if captureSession.canAddOutput(videoOutput) {
      captureSession.addOutput(videoOutput)
    }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = view.bounds
    view.layer.insertSublayer(previewLayer, at: 0)
  }
  
  private func setupOverlayLayers() {
    shadowCornerLayer.strokeColor = UIColor.black.withAlphaComponent(0.55).cgColor
    shadowCornerLayer.lineWidth = 5.5
    shadowCornerLayer.fillColor = UIColor.clear.cgColor
    shadowCornerLayer.lineCap = .round
    shadowCornerLayer.lineJoin = .round
    shadowCornerLayer.opacity = 0
    
    whiteCornerLayer.strokeColor = UIColor.white.cgColor
    whiteCornerLayer.lineWidth = 3
    whiteCornerLayer.fillColor = UIColor.clear.cgColor
    whiteCornerLayer.lineCap = .round
    whiteCornerLayer.lineJoin = .round
    whiteCornerLayer.opacity = 0
    
    view.layer.addSublayer(shadowCornerLayer)
    view.layer.addSublayer(whiteCornerLayer)
  }
}

// MARK: - Corner Detection Handling & Camera Focus
extension OCRViewController {
  private func handleCorners(_ corners: VNRectangleObserver.Corners?) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      
      guard let corners else {
        self.hasConfirmedCard = false
        self.scheduleFadeOut()
        return
      }
      
      let points = self.convertToScreenPoints(corners)
      
      guard self.isMagicTheGatheringRatio(points) else {
        self.hasConfirmedCard = false
        self.scheduleFadeOut()
        return
      }
      
      self.focusCamera(on: points)
      
      guard self.hasConfirmedCard else {
        self.scheduleFadeOut()
        return
      }
      
      self.cancelFadeOut()
      
      let newCornerPath = self.buildCornersPath(for: points)
      let newCrosshairPath = self.buildCrosshairPath(for: points)
      
      if self.isOverlayVisible {
        self.snapPath(corners: newCornerPath, crosshair: newCrosshairPath)
      } else {
        self.setPath(corners: newCornerPath, crosshair: newCrosshairPath)
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
    
    do {
      try device.lockForConfiguration()
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
    } catch {
      print("Could not lock device for configuration: \(error)")
    }
  }
}

// MARK: - Coordinate Conversion
extension OCRViewController {
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
      let sorted = points.sorted { atan2($0.y - centerY, $0.x - centerX) < atan2($1.y - centerY, $1.x - centerX) }
      return [sorted[3], sorted[0], sorted[1], sorted[2]]
    }
    
    return [topLeft!, topRight!, bottomRight!, bottomLeft!]
  }
  
  private static func bestCandidate(_ current: CGPoint?, _ newPoint: CGPoint, _ centerX: CGFloat, _ centerY: CGFloat) -> CGPoint {
    guard let current else { return newPoint }
    return hypot(newPoint.x - centerX, newPoint.y - centerY) < hypot(current.x - centerX, current.y - centerY) ? newPoint : current
  }
}

// MARK: - Path Building
extension OCRViewController {
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
  
  private func buildCrosshairPath(for points: [CGPoint]) -> CGPath {
    guard points.count == 4 else { return CGMutablePath() }
    
    let topLeft = points[0], topRight = points[1], bottomRight = points[2], bottomLeft = points[3]
    
    let centre = CGPoint(
      x: (topLeft.x + topRight.x + bottomRight.x + bottomLeft.x) / 4,
      y: (topLeft.y + topRight.y + bottomRight.y + bottomLeft.y) / 4
    )
    
    let topMiddle = CGPoint(x: (topLeft.x + topRight.x) / 2, y: (topLeft.y + topRight.y) / 2)
    let bottomMiddle = CGPoint(x: (bottomLeft.x + bottomRight.x) / 2, y: (bottomLeft.y + bottomRight.y) / 2)
    let leftMiddle = CGPoint(x: (topLeft.x + bottomLeft.x) / 2, y: (topLeft.y + bottomLeft.y) / 2)
    let rightMiddle = CGPoint(x: (topRight.x + bottomRight.x) / 2, y: (topRight.y + bottomRight.y) / 2)
    
    let horizontalAxis = unitVector(from: leftMiddle,  to: rightMiddle)
    let verticalAxis = unitVector(from: topMiddle,   to: bottomMiddle)
    
    let armLength = min(
      hypot(topRight.x - topLeft.x, topRight.y - topLeft.y),
      hypot(bottomLeft.x - topLeft.x, bottomLeft.y - topLeft.y)
    ) * 0.07
    
    let path = UIBezierPath()
    path.move(to: CGPoint(x: centre.x - horizontalAxis.x * armLength, y: centre.y - horizontalAxis.y * armLength))
    path.addLine(to: CGPoint(x: centre.x + horizontalAxis.x * armLength, y: centre.y + horizontalAxis.y * armLength))
    path.move(to: CGPoint(x: centre.x - verticalAxis.x * armLength, y: centre.y - verticalAxis.y * armLength))
    path.addLine(to: CGPoint(x: centre.x + verticalAxis.x * armLength, y: centre.y + verticalAxis.y * armLength))
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

// MARK: - Animations
extension OCRViewController {
  private func setPath(corners: CGPath, crosshair: CGPath) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    whiteCornerLayer.path = corners
    shadowCornerLayer.path = corners
    CATransaction.commit()
  }
  
  private func snapPath(corners newCorners: CGPath, crosshair newCrosshair: CGPath) {
    func makeAnimation(from layer: CAShapeLayer, to newPath: CGPath) -> CABasicAnimation {
      let animation = CABasicAnimation(keyPath: "path")
      animation.fromValue = layer.presentation()?.path ?? layer.path
      animation.toValue = newPath
      animation.duration = snapDuration
      animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
      animation.fillMode = .forwards
      animation.isRemovedOnCompletion = false
      return animation
    }
    
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    whiteCornerLayer.path = newCorners
    shadowCornerLayer.path = newCorners
    CATransaction.commit()
    
    whiteCornerLayer.add(makeAnimation(from: whiteCornerLayer,   to: newCorners),   forKey: "snapPath")
    shadowCornerLayer.add(makeAnimation(from: shadowCornerLayer, to: newCorners),   forKey: "snapPath")
  }
  
  private func fadeIn() {
    isOverlayVisible = true
    let animation = opacityAnimation(from: 0, to: 1, duration: 0.2)
    whiteCornerLayer.opacity = 1
    shadowCornerLayer.opacity = 1
    whiteCornerLayer.add(animation,                               forKey: "fadeIn")
    shadowCornerLayer.add(animation.copy() as! CABasicAnimation,  forKey: "fadeIn")
  }
  
  private func scheduleFadeOut() {
    guard isOverlayVisible, fadeOutWorkItem == nil else { return }
    let workItem = DispatchWorkItem { [weak self] in
      self?.executeFadeOut()
      self?.fadeOutWorkItem = nil
    }
    fadeOutWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDelay, execute: workItem)
  }
  
  private func cancelFadeOut() {
    fadeOutWorkItem?.cancel()
    fadeOutWorkItem = nil
    guard isOverlayVisible else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    whiteCornerLayer.opacity = 1
    shadowCornerLayer.opacity = 1
    CATransaction.commit()
    whiteCornerLayer.removeAnimation(forKey: "fadeOut")
    shadowCornerLayer.removeAnimation(forKey: "fadeOut")
  }
  
  private func executeFadeOut() {
    isOverlayVisible = false
    hasConfirmedCard = false
    
    let animation = opacityAnimation(from: 1, to: 0, duration: fadeOutDuration)
    animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
    
    CATransaction.begin()
    CATransaction.setCompletionBlock { [weak self] in
      guard let self, !self.isOverlayVisible else { return }
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      self.whiteCornerLayer.path = nil
      self.shadowCornerLayer.path = nil
      CATransaction.commit()
    }
    
    whiteCornerLayer.opacity = 0
    shadowCornerLayer.opacity = 0
    whiteCornerLayer.add(animation, forKey: "fadeOut")
    shadowCornerLayer.add(animation.copy() as! CABasicAnimation, forKey: "fadeOut")
    CATransaction.commit()
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
}

// MARK: - Validation
extension OCRViewController {
  private func isMagicTheGatheringRatio(_ points: [CGPoint]) -> Bool {
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
