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
        )
      ) { state in
        state.image.map { $0.resizable() }
      }
      .aspectRatio(contentMode: .fit)
      .blur(radius: blurRadius, opaque: false)
      .opacity(0.38)
      .scaleEffect(scale)
      .offset(x: offset.x, y: offset.y)
      
      LazyImage(
        request: ImageRequest(
          url: url,
          processors: transformers
        )
      ) { state in
        if state.isLoading {
          RoundedRectangle(cornerRadius: cornerRadius).fill(Color(.systemFill)).shimmering(
            gradient: Gradient(
              colors: [.black.opacity(0.8), .black.opacity(1), .black.opacity(0.8)]
            )
          )
        } else if let image = state.image {
          image.resizable()
        }
      }
      .aspectRatio(contentMode: .fit)
      .clipShape(.rect(cornerSize: CGSize(width: cornerRadius, height: cornerRadius)))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius).stroke(.separator)
      )
    }
  }
}
