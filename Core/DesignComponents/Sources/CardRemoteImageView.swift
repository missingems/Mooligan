import Nuke
import NukeUI
import Shimmer
import SwiftUI

public struct CardRemoteImageView: View {
  public let url: URL
  @State private var cornerRadius: CGFloat?
  private let transformers: [ImageProcessing]
  private let size: CGSize?
  private let isLandscape: Bool
  
  public init(
    url: URL,
    isLandscape: Bool = false,
    isTransformed: Bool = false,
    size: CGSize
  ) {
    self.isLandscape = isLandscape
    self.url = url
    
    var transformers: [ImageProcessing] = []
    
    if isLandscape {
      transformers.append(RotationImageProcessor(degrees: 90))
    }
    
    if isTransformed {
      transformers.append(FlipImageProcessor())
    }
    
    transformers.append(
      ImageProcessors.Resize(
        size: size,
        unit: .points,
        contentMode: .aspectFit,
        crop: false,
        upscale: true
      )
    )
    
    self.transformers = transformers
    self.size = size
  }
  
  public var body: some View {
    LazyImage(
      request: ImageRequest(
        url: url,
        processors: transformers
      ),
      transaction: Transaction(animation: .smooth)
    ) { state in
      if let image = state.image {
        image.resizable().overlay(
          RoundedRectangle(cornerRadius: cornerRadius ?? 0)
            .strokeBorder(.separator)
        )
      } else {
        Color.primary.opacity(0.3).shimmering()
          .blur(radius: 34.0)
          .background(.clear)
      }
    }
    .onGeometryChange(for: CGSize.self, of: { proxy in
      return proxy.size
    }, action: { newValue in
      cornerRadius = 5 / 100 * (isLandscape ? newValue.height : newValue.width)
    })
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? 0))
  }
}
