#if canImport(UIKit)
import SwiftUI

struct ScannerView: UIViewControllerRepresentable {
  struct ScannedResult: Equatable {
    let title: String
    let setCode: String
  }
  
  var onValidatedScan: (ScannedResult) -> Void
  
  func makeCoordinator() -> Coordinator {
    Coordinator(onValidatedScan: onValidatedScan)
  }
  
  func makeUIViewController(context: Context) -> ScannerViewController {
    let controller = ScannerViewController()
    controller.didDetectCard = { value, a in
      
    }
    return controller
  }
  
  func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
  
  final class Coordinator {
    var onValidatedScan: (ScannedResult) -> Void
    
    private var resultBuffer: [ScannedResult] = []
    private let requiredConsistency = 3
    
    init(onValidatedScan: @escaping (ScannedResult) -> Void) {
      self.onValidatedScan = onValidatedScan
    }
    
    func didDetectCard(title: String, setCode: String) {
      let newResult = ScannedResult(title: title, setCode: setCode)
      
      resultBuffer.append(newResult)
      
      if resultBuffer.count > requiredConsistency {
        resultBuffer.removeFirst()
      }
      
      if
        resultBuffer.count == requiredConsistency,
        resultBuffer.allSatisfy({ $0 == newResult })
      {
        onValidatedScan(newResult)
        resultBuffer.removeAll()
      }
    }
  }
}
#endif // canImport(UIKit)
