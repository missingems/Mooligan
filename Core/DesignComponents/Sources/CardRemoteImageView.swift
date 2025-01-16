import Nuke
import NukeUI
import Shimmer
import SwiftUI

struct ConditionalFrameModifier: ViewModifier {
  let size: CGSize
  
  func body(content: Content) -> some View {
    if size.width > 0, size.height > 0 {
      content.frame(width: size.width, height: size.height, alignment: .center)
    }
  }
}

public struct CardRemoteImageView: View {
  public let url: URL
  @State private var cornerRadius: CGFloat?
  private let transformers: [ImageProcessing]
  private let size: CGSize
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
    
    transformers.append(ImageProcessors.Resize(size: size))
    
    self.transformers = transformers
    self.size = size
  }
  
  public var body: some View {
    LazyImage(
      request: ImageRequest(
        url: url,
        processors: transformers
      ),
      transaction: Transaction(animation: .default)
    ) { state in
      Group {
        if let image = state.image {
          image.resizable()
        } else {
          Color.primary.opacity(0.3)
            .shimmering()
            .blur(radius: 34.0)
        }
      }
      .modifier(ConditionalFrameModifier(size: size))
    }
    .onGeometryChange(for: CGSize.self, of: { proxy in
      return proxy.size
    }, action: { newValue in
      cornerRadius = 5 / 100 * (isLandscape ? newValue.height : newValue.width)
    })
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? 0))
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius ?? 0)
        .strokeBorder(.separator, lineWidth: 1 / UIScreen.main.nativeScale)
    )
    .shadow(color: DesignComponentsAsset.shadow.swiftUIColor, radius: 13, x: 0, y: 8)
  }
}
