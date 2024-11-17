import Networking
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
  
  private let isFlippable: Bool
  private let isRotatable: Bool
  private let imageURL: URL?
  private let backImageURL: URL?
  private let layoutConfiguration: LayoutConfiguration
  private let shouldShowPrice: Bool
  private let usdPrice: String?
  private let usdFoilPrice: String?
  private let onFlip: (() -> Void)?
  @State private var isFlipped = false
  @State private var isRotated = false
  
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
                isFlipped: true,
                size: CGSize(
                  width: width,
                  height: height
                )
              )
              .opacity(isFlipped ? 1 : 0)
              .rotationEffect(.degrees(isRotated ? 180 : 0))
              .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
              .animation(.bouncy, value: isFlipped || isRotated)
            }
            
            AmbientWebImage(
              url: imageURL,
              cornerRadius: (5 / 100 * width).rounded(),
              rotation: layoutConfiguration.rotation.degrees,
              isFlipped: false,
              size: CGSize(
                width: width,
                height: height
              )
            )
            .opacity(isFlipped ? 0 : 1)
            .rotationEffect(.degrees(isRotated ? 180 : 0))
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.bouncy, value: isFlipped || isRotated)
            
          case .flexible:
            if let backImageURL {
              AmbientWebImage(
                url: backImageURL,
                cornerRadius: 13.0,
                rotation: layoutConfiguration.rotation.degrees,
                isFlipped: true
              )
              .opacity(isFlipped ? 1 : 0)
              .rotationEffect(.degrees(isRotated ? 180 : 0))
              .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
              .animation(.bouncy, value: isFlipped || isRotated)
            }
            
            AmbientWebImage(
              url: imageURL,
              cornerRadius: 13.0,
              rotation: layoutConfiguration.rotation.degrees,
              isFlipped: false
            )
            .opacity(isFlipped ? 0 : 1)
            .rotationEffect(.degrees(isRotated ? 180 : 0))
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.bouncy, value: isFlipped || isRotated)
          }
        }
        
        buttons
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
    VStack(alignment: .center, spacing: 3.0) {
      if isFlippable {
        Button {
          onFlip?()
          
          withAnimation {
            isFlipped.toggle()
          }
        } label: {
          Image(systemName: "arrow.left.arrow.right").fontWeight(.semibold)
        }
        .tint(DesignComponentsAsset.accentColor.swiftUIColor)
        .frame(width: 44.0, height: 44.0)
        .background(.thinMaterial)
        .clipShape(Circle())
        .overlay(Circle().stroke(.separator, lineWidth: 1).opacity(0.618))
        .offset(x: 5, y: -16.0)
      }
      
      if isRotatable {
        Button {
          withAnimation {
            isRotated.toggle()
          }
        } label: {
          if isRotated {
            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
              .fontWeight(.semibold)
          } else {
            Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
              .fontWeight(.semibold)
          }
        }
        .tint(DesignComponentsAsset.accentColor.swiftUIColor)
        .frame(width: 44.0, height: 44.0)
        .background(.thinMaterial)
        .clipShape(Circle())
        .overlay(Circle().stroke(.separator, lineWidth: 1).opacity(0.618))
        .offset(x: 5, y: -16.0)
      }
    }
  }
  
  public init(
    imageURL: URL?,
    backImageURL: URL?,
    isFlippable: Bool,
    isRotatable: Bool,
    layoutConfiguration: LayoutConfiguration,
    usdPrice: String?,
    usdFoilPrice: String?,
    shouldShowPrice: Bool = true,
    onFlip: (() -> Void)? = nil
  ) {
    self.imageURL = imageURL
    
    if isFlippable {
      self.backImageURL = backImageURL
    } else {
      self.backImageURL = nil
    }
    
    self.layoutConfiguration = layoutConfiguration
    self.shouldShowPrice = shouldShowPrice
    self.isFlippable = isFlippable
    self.isRotatable = isRotatable
    self.usdPrice = usdPrice
    self.usdFoilPrice = usdFoilPrice
    self.onFlip = onFlip
  }
}
