import Nuke
import Shimmer
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
      } else {
        Circle().fill(Color.primary.opacity(0.9)).shimmering()
          .blur(radius: 8)
      }
    }
    .task(priority: .background) {
      guard let url else { return }
      
      ImagePipeline.shared.loadImage(with: url) { result in
        switch result {
        case let .success(value):
          if value.cacheType == .memory || value.cacheType == .disk {
            imageData = value.container.data
          } else {
            withAnimation(.smooth) {
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
