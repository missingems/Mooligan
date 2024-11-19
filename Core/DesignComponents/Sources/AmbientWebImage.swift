import Nuke
import NukeUI
import Shimmer
import Sticker
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
  
  public init(
    url: URL,
    cornerRadius: CGFloat = 9,
    rotation: CGFloat = 0,
    isFlipped: Bool = false,
    size: CGSize? = nil
  ) {
    self.url = url
    self.cornerRadius = cornerRadius
    
    var transformers: [ImageProcessing] = []
    
    if rotation != 0 {
      transformers.append(RotationImageProcessor(degrees: rotation))
    }
    
    if isFlipped {
      transformers.append(FlipImageProcessor())
    }
    
    transformers.append(ImageProcessors.RoundedCorners(radius: cornerRadius, unit: .points, border: nil))
    
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
  }
  
  public var body: some View {
    LazyImage(
      request: ImageRequest(
        url: url,
        processors: transformers
      ),
      transaction: Transaction(animation: .easeInOut(duration: 0.31))
    ) { state in
      if let image = state.image {
        image.resizable().animation(.bouncy) { view in
          view
            .stickerEffect()
            .stickerColorIntensity(0.2)
            .stickerScale(3.0)
            .stickerNoiseScale(200)
            .stickerLightIntensity(0.25)
            .stickerContrast(0.45)
            .stickerColorIntensity(0.4)
            .stickerBlend(0.4)
            .stickerMotionEffect(.dragGesture(intensity: 0.5))
        }
      } else {
        Color
          .primary
          .opacity(0.02)
          .background(.ultraThinMaterial)
          .shimmering(
            gradient: Gradient(
              colors: [
                .clear,
                .white.opacity(0.32),
                .clear
              ]
            ),
            mode: .overlay()
          )
          .clipShape(.rect(cornerRadius: cornerRadius))
      }
    }
    .modifier(ConditionalFrameModifier(size: size))
  }
}
