import SwiftUI

public struct CardScannerView: View {
  @Binding public var title: String
  @Binding public var setCode: String
  
  public init(
    title: Binding<String>,
    setCode: Binding<String>
  ) {
    self._title = title
    self._setCode = setCode
  }
  
  public var body: some View {
    ScannerView { result in
      self.title = result.title
      self.setCode = result.setCode
    }
  }
}
