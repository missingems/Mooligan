import UIKit
import AVFoundation

final class OCRViewController: UIViewController {
  var didDetectResult: ((OCRCardScannedResult) -> Void)?
  
  private let captureSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated)
  private let boundingBoxLayer = CAShapeLayer()
  private let captureDelegate = OCRCaptureDelegate()
  private let sessionQueue = DispatchQueue(label: "CaptureSessionQueue")
  
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
    captureDelegate.onDrawBox = { [weak self] corners in
      self?.drawBox(corners)
    }
    
    captureDelegate.onDetectCard = { [weak self] result in
      self?.didDetectResult?(result)
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
    
    boundingBoxLayer.strokeColor = UIColor.green.cgColor
    boundingBoxLayer.lineWidth = 3
    boundingBoxLayer.fillColor = UIColor.green.withAlphaComponent(0.1).cgColor
    view.layer.addSublayer(boundingBoxLayer)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    sessionQueue.async { [weak self] in
      self?.captureSession.startRunning()
    }
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    sessionQueue.async { [weak self] in
      self?.captureSession.stopRunning()
    }
  }
  
  private func drawBox(_ corners: VNRectangleObserver.Corners?) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.boundingBoxLayer.path = nil
      guard let corners = corners else { return }

      let converted = [
        corners.topLeft,
        corners.topRight,
        corners.bottomRight,
        corners.bottomLeft
      ].map { point -> CGPoint in
        self.previewLayer.layerPointConverted(
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

      self.boundingBoxLayer.path = path.cgPath
    }
  }
}
