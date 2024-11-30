import Nuke
import SVGView
import SwiftUI

public struct IconLazyImage: View {
  private let url: URL?
  @State private var imageData: Data?
  private let tintColor: Color
  
  public init(_ url: URL?, tintColor: Color = DesignComponentsAsset.accentColor.swiftUIColor) {
    self.url = url
    self.tintColor = tintColor
  }
  
  public var body: some View {
    ZStack {
      if let imageData {
        tintColor.mask {
          SVGView(data: imageData)
        }
      }
    }
    .task(priority: .background) {
      guard let url else { return }
      
      ImagePipeline.shared.loadImage(with: url) { result in
        imageData = try? result.get().container.data
      }
    }
  }
}
