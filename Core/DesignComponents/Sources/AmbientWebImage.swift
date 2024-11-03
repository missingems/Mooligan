import Nuke
import NukeUI
import SwiftUI
import Shimmer

public struct AmbientWebImage: View {
  public let url: URL
  private let cornerRadius: CGFloat
  private let transformers: [ImageProcessing]
  
  public init(
    url: URL,
    cornerRadius: CGFloat = 9,
    rotation: CGFloat = 0,
    isFlipped: Bool = false
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
    
    self.transformers = transformers
  }
  
  public var body: some View {
    LazyImage(
      request: ImageRequest(
        url: url,
        processors: transformers
      ),
      transaction: Transaction(animation: .easeInOut(duration: 0.31))
    ) { state in
      if state.isLoading {
        RoundedRectangle(cornerRadius: cornerRadius).fill(Color(.systemFill)).shimmering()
      } else if let image = state.image {
        image.resizable()
      }
    }
    .clipShape(.rect(cornerSize: CGSize(width: cornerRadius, height: cornerRadius)))
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(Color.white.opacity(0.31), lineWidth: 1 / UIScreen.main.nativeScale)
    )
  }
}
