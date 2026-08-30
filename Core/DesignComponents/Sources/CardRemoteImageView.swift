import Nuke
import NukeUI
import Shimmer
import SwiftUI

public struct CardRemoteImageView: View {
  public let url: URL
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) private var displayScale
  @State private var measuredCornerRadius: CGFloat?
  @Binding var isImageLoaded: Bool
  
  private let size: CGSize?
  private let isLandscape: Bool
  private let id: String
  private let imageRequest: ImageRequest
  
  public init(
    url: URL,
    isLandscape: Bool = false,
    isTransformed: Bool = false,
    size: CGSize? = nil,
    id: String,
    priority: ImageRequest.Priority = .normal,
    isImageLoaded: Binding<Bool>
  ) {
    self.url = url
    self.isLandscape = isLandscape
    self.size = size
    self.id = id
    
    self._isImageLoaded = isImageLoaded
    
    var transformers: [ImageProcessing] = []
    if isLandscape {
      transformers.append(RotationImageProcessor(degrees: 90))
    }
    
    if isTransformed {
      transformers.append(FlipImageProcessor())
    }
    
    self.imageRequest = ImageRequest(
      url: url,
      processors: transformers,
      priority: priority
    )
  }
  
  private var cornerRadius: CGFloat {
    if let size {
      return 5 / 100 * (isLandscape ? size.height : size.width)
    }
    return measuredCornerRadius ?? 0
  }
  
  public var body: some View {
    LazyImage(
      request: imageRequest,
      transaction: Transaction(animation: .smooth)
    ) { state in
      Color.primary.opacity(0.116).overlay {
        if let image = state.image {
          image.resizable()
            .onAppear {
              if isImageLoaded != true {
                isImageLoaded = true
              }
            }
        }
      }
      .shimmering(active: state.image == nil, bandSize: 0.7)
    }
    .frame(width: size?.width, height: size?.height)
    .aspectRatio(size == nil ? MagicCardImageRatio.widthToHeight.rawValue : nil, contentMode: .fit)
    .modifier(
      MeasureCornerRadiusIfNeeded(
        isLandscape: isLandscape,
        needsMeasurement: size == nil,
        measuredCornerRadius: $measuredCornerRadius
      )
    )
    .clipShape(
      RoundedRectangle(cornerRadius: cornerRadius)
    )
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(
          (colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225)).blendMode(
            colorScheme == .dark ? .plusLighter : .plusDarker
          ),
          lineWidth: 1 / displayScale
        )
    )
  }
}

private struct MeasureCornerRadiusIfNeeded: ViewModifier {
  let isLandscape: Bool
  let needsMeasurement: Bool
  @Binding var measuredCornerRadius: CGFloat?
  
  func body(content: Content) -> some View {
    if needsMeasurement {
      content.onGeometryChange(
        for: CGSize.self,
        of: { proxy in proxy.size },
        action: { newValue in
          if measuredCornerRadius == nil {
            measuredCornerRadius = 5 / 100 * (isLandscape ? newValue.height : newValue.width)
          }
        }
      )
    } else {
      content
    }
  }
}
