import Nuke
import NukeUI
import Shimmer
import SwiftUI

public struct CardRemoteImageView: View {
  public let url: URL
  @Environment(\.displayScale) private var displayScale
  
  private let cornerRadius: CGFloat
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
    self.size = size
    self.id = id
    
    if let size {
      self.cornerRadius = (5.0 / 100.0) * (isLandscape ? size.height : size.width)
    } else {
      self.cornerRadius = 0
    }
    
    var transformers: [ImageProcessing] = []
    if isLandscape { transformers.append(RotationImageProcessor(degrees: 90)) }
    if isTransformed { transformers.append(FlipImageProcessor()) }
    self.transformers = transformers
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
      .aspectRatio(MagicCardImageRatio.widthToHeight.rawValue, contentMode: .fit)
    }
    .aspectRatio(MagicCardImageRatio.widthToHeight.rawValue, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius)
        .strokeBorder(.separator, lineWidth: 1 / displayScale)
    )
  }
}
