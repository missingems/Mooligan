import Nuke
import NukeUI
import Shimmer
import SwiftUI

public struct CardRemoteImageView: View {
  public let url: URL
  
  @Environment(\.displayScale) private var displayScale
  @State private var cornerRadius: CGFloat?
  @Binding var isImageLoaded: Bool
  
  private let transformers: [ImageProcessing]
  private let size: CGSize?
  private let isLandscape: Bool
  private let id: String
  private let priority: ImageRequest.Priority
  
  public init(
    url: URL,
    isLandscape: Bool = false,
    isTransformed: Bool = false,
    size: CGSize? = nil,
    id: String,
    priority: ImageRequest.Priority = .normal,
    isImageLoaded: Binding<Bool> // 2. Add to init
  ) {
    self.url = url
    self.isLandscape = isLandscape
    self.size = size
    self.id = id
    self.priority = priority
    
    self._isImageLoaded = isImageLoaded
    var transformers: [ImageProcessing] = []
    
    if isLandscape {
      transformers.append(RotationImageProcessor(degrees: 90))
    }
    
    if isTransformed {
      transformers.append(FlipImageProcessor())
    }
    
    self.transformers = transformers
  }
  
  public var body: some View {
    LazyImage(
      request: ImageRequest(
        url: url,
        processors: transformers,
        priority: priority
      ),
      transaction: Transaction(animation: .easeInOut(duration: 0.125))
    ) { state in
      Group {
        if let image = state.image {
          image.resizable()
            .onAppear {
              if isImageLoaded != true {
                isImageLoaded = true
              }
            }
        } else {
          Color.primary.opacity(0.3)
            .shimmering()
            .blur(radius: 34.0)
        }
      }
    }
    .aspectRatio(MagicCardImageRatio.widthToHeight.rawValue, contentMode: .fit)
    .onGeometryChange(
      for: CGSize.self,
      of: { proxy in
        proxy.size
      },
      action: { newValue in
        if cornerRadius == nil {
          cornerRadius = 5 / 100 * (isLandscape ? newValue.height : newValue.width)
        }
      }
    )
    .clipShape(
      RoundedRectangle(cornerRadius: cornerRadius ?? 0)
    )
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius ?? 0)
        .stroke(.white.opacity(0.168), lineWidth: 1 / displayScale)
    )
  }
}
