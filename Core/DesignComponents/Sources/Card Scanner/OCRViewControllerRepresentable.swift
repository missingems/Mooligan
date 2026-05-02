import SwiftUI

struct OCRViewRepresentable: UIViewControllerRepresentable {
  var isScanningPaused: Bool
  var isProcessingFrame: Bool
  var isTrackingPaused: Bool
  var onValidatedScan: (ScannedImage) -> Void
  var onTrackingUpdate: (QuadCorners?) -> Void
  
  func makeUIViewController(context: Context) -> OCRViewController {
    let vc = OCRViewController()
    vc.didDetectResult = onValidatedScan
    vc.didUpdateTrackingCorners = onTrackingUpdate
    return vc
  }
  
  func updateUIViewController(_ uiViewController: OCRViewController, context: Context) {
    uiViewController.isScanningPaused = isScanningPaused
    uiViewController.isProcessingFrame = isProcessingFrame
    uiViewController.isTrackingPaused = isTrackingPaused
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(onValidatedScan: onValidatedScan)
  }
  
  final class Coordinator {
    var onValidatedScan: (ScannedImage) -> Void
    private var resultBuffer: [ScannedImage] = []
    private let requiredConsistency = 0
    
    init(onValidatedScan: @escaping (ScannedImage) -> Void) {
      self.onValidatedScan = onValidatedScan
    }
    
    func didDetect(result: ScannedImage) {
      resultBuffer.append(result)
      if resultBuffer.count > requiredConsistency {
        resultBuffer.removeFirst()
      }
      if resultBuffer.count == requiredConsistency, resultBuffer.allSatisfy({ $0 == result }) {
        onValidatedScan(result)
        resultBuffer.removeAll()
      }
    }
  }
}
