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
    tintColor.mask {
      if let imageData {
        SVGView(data: imageData)
      }
    }
    .opacity(imageData == nil ? 0 : 1)
    .blur(radius: imageData == nil ? 5 : 0)
    .task(priority: .background) {
      guard let url else { return }
      
      ImagePipeline.shared.loadImage(with: url) { result in
        switch result {
        case let .success(value):
          if value.cacheType == .memory || value.cacheType == .disk {
            imageData = value.container.data
          } else {
            withAnimation(.snappy) {
              imageData = value.container.data
            }
          }
          
        case .failure:
          imageData = nil
        }
      }
    }
  }
}
