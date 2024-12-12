import Nuke
import NukeUI
import Shimmer
import SwiftUI

struct ConditionalFrameModifier: ViewModifier {
  let size: CGSize?
  
  func body(content: Content) -> some View {
    if let size = size {
      content.frame(width: size.width, height: size.height, alignment: .center)
    } else {
      content
    }
  }
}

public struct AmbientWebImage: View {
  public let url: URL
  private let cornerRadius: CGFloat
  private let transformers: [ImageProcessing]
  private let size: CGSize?
  private let isImageLoaded: Binding<Bool>
  
  public init(
    url: URL,
    cornerRadius: CGFloat = 0,
    rotation: CGFloat = 0,
    isTransformed: Bool = false,
    size: CGSize? = nil,
    isImageLoaded: Binding<Bool>
  ) {
    self.url = url
    self.cornerRadius = cornerRadius
    
    var transformers: [ImageProcessing] = []
    
    if rotation != 0 {
      transformers.append(RotationImageProcessor(degrees: rotation))
    }
    
    if isTransformed {
      transformers.append(FlipImageProcessor())
    }
    
    if let size {
      transformers.append(
        ImageProcessors.Resize(
          size: size,
          unit: .points,
          contentMode: .aspectFit,
          crop: false,
          upscale: true
        )
      )
    }
    
    self.transformers = transformers
    self.size = size
    self.isImageLoaded = isImageLoaded
  }
  
  public var body: some View {
    LazyImage(
      request: ImageRequest(
        url: url,
        processors: transformers
      ),
      transaction: Transaction(animation: .interpolatingSpring)
    ) { state in
      if let image = state.image {
        image.resizable().task {
          isImageLoaded.wrappedValue = true
        }
      } else {
        Color.primary.opacity(0.3).shimmering()
          .blur(radius: 34.0)
          .background(.clear)
      }
    }
    .modifier(ConditionalFrameModifier(size: size))
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(.separator, lineWidth: 1 / UIScreen.main.nativeScale)
    )
  }
}

