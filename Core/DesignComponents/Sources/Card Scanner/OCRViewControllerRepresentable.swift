import SwiftUI

public struct OCRCardScannedResult: Equatable, Sendable {
  let title: String
  let setCode: String
  
  public init(title: String, setCode: String) {
    self.title = title
    self.setCode = setCode
  }
}

struct OCRViewControllerRepresentable: UIViewControllerRepresentable {
  var onValidatedScan: (OCRCardScannedResult) -> Void
  
  func makeCoordinator() -> Coordinator {
    Coordinator(onValidatedScan: onValidatedScan)
  }
  
  func makeUIViewController(context: Context) -> OCRViewController {
    let controller = OCRViewController()
    
    controller.didDetectCard = { title, setCode in
      context.coordinator.didDetectCard(title: title, setCode: setCode)
    }
    
    return controller
  }
  
  func updateUIViewController(_ uiViewController: OCRViewController, context: Context) {
    context.coordinator.onValidatedScan = onValidatedScan
  }
  
  final class Coordinator {
    var onValidatedScan: (OCRCardScannedResult) -> Void
    
    private var resultBuffer: [OCRCardScannedResult] = []
    private let requiredConsistency = 3
    
    init(onValidatedScan: @escaping (OCRCardScannedResult) -> Void) {
      self.onValidatedScan = onValidatedScan
    }
    
    func didDetectCard(title: String, setCode: String) {
      let newResult = OCRCardScannedResult(title: title, setCode: setCode)
      
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
