import SwiftUI

struct OCRViewControllerRepresentable: UIViewControllerRepresentable {
  var onValidatedScan: (CardImageResult) -> Void
  
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
    var onValidatedScan: (CardImageResult) -> Void
    
    private var resultBuffer: [CardImageResult] = []
    private let requiredConsistency = 3
    
    init(onValidatedScan: @escaping (CardImageResult) -> Void) {
      self.onValidatedScan = onValidatedScan
    }
    
    func didDetect(result: CardImageResult) {
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
