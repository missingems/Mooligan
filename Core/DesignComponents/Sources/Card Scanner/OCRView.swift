
import SwiftUI

public struct OCRView: View {
  @Binding public var result: OCRCardScannedResult
  
  public init(
    result: Binding<OCRCardScannedResult>,
  ) {
    self._result = result
  }
  
  public var body: some View {
    OCRViewControllerRepresentable { result in
      self.result = result
    }
  }
}
