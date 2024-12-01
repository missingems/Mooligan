
import SwiftUI

public struct CardView: View {
  public struct LayoutConfiguration {
    public enum Layout {
      case fixedWidth(CGFloat)
      case flexible
    }
    
    public enum Rotation {
      case landscape
      case portrait
      
      var degrees: CGFloat {
        switch self {
        case .landscape: return 90
        case .portrait: return 0
        }
      }
      
      public var ratio: CGFloat {
        switch self {
        case .landscape: return MagicCardImageRatio.heightToWidth.rawValue
        case .portrait: return MagicCardImageRatio.widthToHeight.rawValue
        }
      }
    }
    
    public let rotation: Rotation
    public let layout: Layout
    
    public init(rotation: Rotation, layout: Layout) {
      self.rotation = rotation
      self.layout = layout
    }
  }
  
  private let isTransformable: Bool
  private let isFlippable: Bool
  private let imageURL: URL?
  private let backImageURL: URL?
  private let layoutConfiguration: LayoutConfiguration
  private let shouldShowPrice: Bool
  private let usdPrice: String?
  private let usdFoilPrice: String?
  @Binding private var isTransformed: Bool?
  @State private var isTransformedInternal = false
  @Binding private var isFlipped: Bool?
  @State private var isFlippedInternal = false
  
  public var body: some View {
    VStack(spacing: 5) {
      ZStack(alignment: .trailing) {
        if let imageURL {
          switch layoutConfiguration.layout {
          case let .fixedWidth(width):
            let width = width.rounded()
            let height = (width / layoutConfiguration.rotation.ratio).rounded()
            
            if let backImageURL {
              AmbientWebImage(
                url: backImageURL,
                cornerRadius: (5 / 100 * width).rounded(),
                rotation: layoutConfiguration.rotation.degrees,
                isTransformed: true,
                size: CGSize(
                  width: width,
                  height: height
                )
              )
              .opacity(isTransformed ?? isTransformedInternal ? 1 : 0)
              .rotationEffect(.degrees(isFlipped ?? isFlippedInternal ? 180 : 0))
              .rotation3DEffect(.degrees(isTransformed ?? isTransformedInternal ? 180 : 0), axis: (x: 0, y: 1, z: 0))
              .animation(.bouncy, value: isTransformed ?? isTransformedInternal || isFlipped ?? isFlippedInternal)
              .zIndex(isTransformed ?? isTransformedInternal ? 1 : 0)
            }
            
            AmbientWebImage(
              url: imageURL,
              cornerRadius: (5 / 100 * width).rounded(),
              rotation: layoutConfiguration.rotation.degrees,
              isTransformed: false,
              size: CGSize(
                width: width,
                height: height
              )
            )
            .opacity(isTransformed ?? isTransformedInternal ? 0 : 1)
            .rotationEffect(.degrees(isFlipped ?? isFlippedInternal ? 180 : 0))
            .rotation3DEffect(.degrees(isTransformed ?? isTransformedInternal ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.bouncy, value: isTransformed ?? isTransformedInternal || isFlipped ?? isFlippedInternal)
            .zIndex(isTransformed ?? isTransformedInternal ? 0 : 1)
            
          case .flexible:
            if let backImageURL {
              AmbientWebImage(
                url: backImageURL,
                cornerRadius: 15.0,
                rotation: layoutConfiguration.rotation.degrees,
                isTransformed: true
              )
              .opacity(isTransformed ?? isTransformedInternal ? 1 : 0)
              .rotationEffect(.degrees(isFlipped ?? isFlippedInternal ? 180 : 0))
              .rotation3DEffect(.degrees(isTransformed ?? isTransformedInternal ? 180 : 0), axis: (x: 0, y: 1, z: 0))
              .animation(.bouncy, value: isTransformed ?? isTransformedInternal || isFlipped ?? isFlippedInternal)
              .zIndex(isTransformed ?? isTransformedInternal ? 1 : 0)
            }
            
            AmbientWebImage(
              url: imageURL,
              cornerRadius: 15.0,
              rotation: layoutConfiguration.rotation.degrees,
              isTransformed: false
            )
            .opacity(isTransformed ?? isTransformedInternal ? 0 : 1)
            .rotationEffect(.degrees(isFlipped ?? isFlippedInternal ? 180 : 0))
            .rotation3DEffect(.degrees(isTransformed ?? isTransformedInternal ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.bouncy, value: isTransformed ?? isTransformedInternal || isFlipped ?? isFlippedInternal)
            .zIndex(isTransformed ?? isTransformedInternal ? 0 : 1)
          }
        }
        
        buttons.zIndex(2)
      }
      .zIndex(1)
      
      priceView
    }
  }
  
  @ViewBuilder private var priceView: some View {
    if shouldShowPrice {
      HStack(spacing: 5) {
        if let usd = usdPrice {
          PillText("$\(usd)")
        }
        
        if let foil = usdFoilPrice {
          PillText(
            "$\(foil)",
            isFoil: true
          )
          .foregroundStyle(.black.opacity(0.8))
        }
        
        if usdPrice == nil && usdFoilPrice == nil {
          PillText("$0.00")
        }
      }
      .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
      .font(.caption)
      .fontWeight(.medium)
      .monospaced()
      .padding(.bottom, 5.0)
    }
  }
  
  @ViewBuilder private var buttons: some View {
    if isFlippable {
      Button {
        withAnimation(.bouncy) {
          if isFlipped != nil {
            isFlipped?.toggle()
          } else {
            isFlippedInternal.toggle()
          }
        }
      } label: {
        Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
          .fontWeight(.semibold)
      }
      .tint(DesignComponentsAsset.accentColor.swiftUIColor)
      .frame(width: 44.0, height: 44.0)
      .background(.thinMaterial)
      .clipShape(Circle())
      .overlay(Circle().stroke(.separator, lineWidth: 1).opacity(0.618))
      .offset(x: 5, y: -13)
    } else if isTransformable {
      Button {
        withAnimation(.bouncy) {
          if isTransformed != nil {
            isTransformed?.toggle()
          } else {
            isTransformedInternal.toggle()
          }
        }
      } label: {
        Image(systemName: "arrow.left.arrow.right").fontWeight(.semibold)
      }
      .tint(DesignComponentsAsset.accentColor.swiftUIColor)
      .frame(width: 44.0, height: 44.0)
      .background(.thinMaterial)
      .clipShape(Circle())
      .overlay(Circle().stroke(.separator, lineWidth: 1).opacity(0.618))
      .offset(x: 5, y: -13)
    }
  }
  
  public init(
    imageURL: URL?,
    backImageURL: URL?,
    isTransformable: Bool,
    isTransformed: Binding<Bool?>? = nil,
    isFlippable: Bool,
    isFlipped: Binding<Bool?>? = nil,
    layoutConfiguration: LayoutConfiguration,
    usdPrice: String?,
    usdFoilPrice: String?,
    shouldShowPrice: Bool = true
  ) {
    self.imageURL = imageURL
    
    if isTransformable {
      self.backImageURL = backImageURL
    } else {
      self.backImageURL = nil
    }
    
    self.layoutConfiguration = layoutConfiguration
    self.shouldShowPrice = shouldShowPrice
    self.isTransformable = isTransformable
    self.isFlippable = isFlippable
    self.usdPrice = usdPrice
    self.usdFoilPrice = usdFoilPrice
    self._isTransformed = isTransformed ?? .constant(nil)
    self.isTransformedInternal = false
    self._isFlipped = isFlipped ?? .constant(nil)
    self.isFlippedInternal = false
  }
}
