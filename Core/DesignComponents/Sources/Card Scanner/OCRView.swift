
import SwiftUI

public struct OCRView: View {
  var onUpdate: (OCRCardScannedResult) -> Void
  
  public init(
    onUpdate: @escaping (OCRCardScannedResult) -> Void
  ) {
    self.onUpdate = onUpdate
  }
  
  public var body: some View {
    OCRViewControllerRepresentable(
      onValidatedScan: onUpdate
    )
  }
}
