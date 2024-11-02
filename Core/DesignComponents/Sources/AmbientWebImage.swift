import Nuke
import NukeUI
import SwiftUI
import Shimmer

public struct AmbientWebImage: View {
  public let url: URL
  private let cornerRadius: CGFloat
  private let blurRadius: CGFloat
  private let offset: CGPoint
  private let scale: CGSize
  private let transformers: [ImageProcessing]
  
  public init(
    url: URL,
    cornerRadius: CGFloat = 9,
    blurRadius: CGFloat = 13,
    offset: CGPoint = CGPoint(x: 0, y: 8),
    scale: CGSize = CGSize(width: 1.05, height: 1.05),
    rotation: CGFloat = 0
  ) {
    self.url = url
    self.cornerRadius = cornerRadius
    self.blurRadius = blurRadius
    self.offset = offset
    self.scale = scale
    
    var transformers: [ImageProcessing] = []
    
    if rotation != 0 {
      transformers.append(RotationImageProcessor(degrees: rotation))
    }
    
    self.transformers = transformers
  }
  
  public var body: some View {
    ZStack {
      LazyImage(
        request: ImageRequest(
          url: url,
          processors: transformers
        ),
        transaction: Transaction(animation: .easeInOut(duration: 0.31))
      ) { state in
        state.image.map { $0.resizable() }
      }
      .blur(radius: blurRadius, opaque: false)
      .opacity(0.2)
      .scaleEffect(scale)
      .offset(x: offset.x, y: offset.y)
      
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
}
