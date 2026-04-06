import SwiftUI

public struct OCRView: View {
  var onUpdate: (ScannedImage) -> Void
  
  public init(
    onUpdate: @escaping (ScannedImage) -> Void
  ) {
    self.onUpdate = onUpdate
  }
  
  public var body: some View {
    OCRViewControllerRepresentable(
      onValidatedScan: onUpdate
    )
  }
}
