import Nuke
import NukeUI
import Shimmer
import SwiftUI

public struct CardRemoteImageView: View {
  public let url: URL
  @Environment(\.displayScale) private var displayScale
  private let transformers: [ImageProcessing]
  private let size: CGSize?
  private let isLandscape: Bool
  private let id: String
  
  public init(
    url: URL,
    isLandscape: Bool = false,
    isTransformed: Bool = false,
    size: CGSize? = nil,
    id: String
  ) {
    self.isLandscape = isLandscape
    self.url = url
    
    var processors: [ImageProcessing] = [
      // ✨ FIX 1: Downsample images on a background thread!
      // This stops the UI from freezing when trying to decode
      // massive 672x936 MTG bitmaps during a scroll event.
      ImageProcessors.Resize(width: 400)
    ]
    
    if isLandscape {
      processors.append(RotationImageProcessor(degrees: 90))
    }
    
    if isTransformed {
      processors.append(FlipImageProcessor())
    }
    
    self.transformers = processors
    self.size = size
    self.id = id
  }
  
  public var body: some View {
    // ✨ FIX 2: Replaced the @State and .onGeometryChange with an inline proxy.
    // This perfectly calculates the relative MTG corner radius without
    // ever mutating state, completely eliminating the AttributeGraph infinite loops.
    GeometryReader { proxy in
      let dynamicRadius = 0.0475 * (isLandscape ? proxy.size.height : proxy.size.width)
      
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
      }
      .clipShape(RoundedRectangle(cornerRadius: dynamicRadius))
      .overlay(
        RoundedRectangle(cornerRadius: dynamicRadius)
          .strokeBorder(.separator, lineWidth: 1 / displayScale)
      )
    }
    .aspectRatio(MagicCardImageRatio.widthToHeight.rawValue, contentMode: .fit)
  }
}
