import SwiftUI

public struct OCRView: View {
  var onUpdate: (CardImageResult) -> Void
  
  public init(
    onUpdate: @escaping (CardImageResult) -> Void
  ) {
    self.onUpdate = onUpdate
  }
  
  public var body: some View {
    OCRViewControllerRepresentable(
      onValidatedScan: onUpdate
    )
  }
}
