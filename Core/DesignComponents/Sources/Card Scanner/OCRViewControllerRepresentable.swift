import SwiftUI

struct OCRViewControllerRepresentable: UIViewControllerRepresentable {
  var onValidatedScan: (ScannedImage) -> Void
  
  func makeCoordinator() -> Coordinator {
    Coordinator(onValidatedScan: onValidatedScan)
  }
  
  func makeUIViewController(context: Context) -> OCRViewController {
    let controller = OCRViewController()
    
    controller.didDetectResult = { result in
      context.coordinator.didDetect(result: result)
    }
    
    return controller
  }
  
  func updateUIViewController(_ uiViewController: OCRViewController, context: Context) {
    context.coordinator.onValidatedScan = onValidatedScan
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
      
      if
        resultBuffer.count == requiredConsistency,
        resultBuffer.allSatisfy({ $0 == result })
      {
        onValidatedScan(result)
        resultBuffer.removeAll()
      }
    }
  }
}
