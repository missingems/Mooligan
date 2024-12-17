import SwiftUI

public struct CardView: View {
  public enum Model {
    case transformable(displayingImageURL: URL, frontImageURL: URL, backImageURL: URL)
    case flippable(displayingImageURL: URL, frontImageURL: URL, backImageURL: URL)
    case single(displayingImageURL: URL)
  }
  
  public struct LayoutConfiguration {
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
    public let maxWidth: CGFloat
    public let cornerRadius: CGFloat
    
    public var size: CGSize {
      switch rotation {
      case .landscape:
        return CGSize(width: maxWidth, height: (maxWidth * MagicCardImageRatio.widthToHeight.rawValue).rounded())
        
      case .portrait:
        return CGSize(width: maxWidth, height: (maxWidth * MagicCardImageRatio.heightToWidth.rawValue).rounded())
      }
    }
    
    public init(rotation: Rotation, maxWidth: CGFloat) {
      self.rotation = rotation
      self.maxWidth = maxWidth
      
      switch rotation {
      case .landscape:
        self.cornerRadius = 5 / 100 * maxWidth * MagicCardImageRatio.widthToHeight.rawValue
        
      case .portrait:
        self.cornerRadius = 5 / 100 * maxWidth
      }
    }
  }
//  
//  private let isTransformable: Bool
//  private let isFlippable: Bool
//  private let imageURL: URL?
//  private let backImageURL: URL?
  private let layoutConfiguration: LayoutConfiguration
//  private let shouldShowPrice: Bool
//  private let usdPrice: String?
//  private let usdFoilPrice: String?
//  private let callToActionIconName: String?
  private let callToActionHorizontalOffset: CGFloat
//  @Binding private var isTransformed: Bool?
//  @State private var isTransformedInternal = false
//  @Binding private var isFlipped: Bool?
//  @State private var isFlippedInternal = false
  @State private var test = false
  private let model: Model
  
  public var body: some View {
    VStack(spacing: 5) {
      ZStack(alignment: .trailing) {
        switch model {
        case let .transformable(displayingImageURL, frontImageURL, backImageURL):
          Text("Hello World")
        case let .flippable(displayingImageURL, frontImageURL, backImageURL):
          Text("Hello World")
          
        case let .single(displayingImageURL):
          AmbientWebImage(
            url: displayingImageURL,
            cornerRadius: layoutConfiguration.cornerRadius.rounded(),
            rotation: layoutConfiguration.rotation.degrees,
            isTransformed: false,
            size: layoutConfiguration.size
          ).opacity(test ? 1 : 0)
          
          Button {
            withAnimation {
              test.toggle()
            } completion: {
              print("done")
            }

            
          } label: {
            Text("Test")
          }

        }
        
        
//        if let imageURL {
//          switch layoutConfiguration.layout {
//          case let .fixedWidth(width):
//            let width = width.rounded()
//            let height = (width / layoutConfiguration.rotation.ratio).rounded()
//            
//            if let backImageURL {
//              AmbientWebImage(
//                url: backImageURL,
//                cornerRadius: layoutConfiguration.cornerRadius.rounded(),
//                rotation: layoutConfiguration.rotation.degrees,
//                isTransformed: true,
//                size: CGSize(
//                  width: width,
//                  height: height
//                ),
//                isImageLoaded: $isImageLoaded
//              )
//              .opacity(isTransformedInternal ? 1 : 0)
//              .rotationEffect(.degrees(isFlippedInternal ? 180 : 0))
//              .rotation3DEffect(.degrees(isTransformedInternal ? 180 : 0), axis: (x: 0, y: 1, z: 0))
//              .zIndex(isTransformedInternal ? 1 : 0)
//              .animation(.bouncy, value: isTransformedInternal)
//            }
//            
//            AmbientWebImage(
//              url: imageURL,
//              cornerRadius: layoutConfiguration.cornerRadius.rounded(),
//              rotation: layoutConfiguration.rotation.degrees,
//              isTransformed: false,
//              size: CGSize(
//                width: width,
//                height: height
//              ),
//              isImageLoaded: $isImageLoaded
//            )
//            .opacity(isTransformedInternal ? 0 : 1)
//            .rotationEffect(.degrees(isFlippedInternal ? 180 : 0))
//            .rotation3DEffect(.degrees(isTransformedInternal ? 180 : 0), axis: (x: 0, y: 1, z: 0))
//            .zIndex(isTransformedInternal ? 0 : 1)
//            .animation(.bouncy, value: isTransformedInternal)
//          }
//        }
        
//        if isFlippable {
//          Button {
//            
//            isFlippedInternal.toggle()
//          } label: {
//            if let iconName = callToActionIconName {
//              Image(systemName: iconName)
//                .fontWeight(.semibold)
//            }
//          }
//          .tint(DesignComponentsAsset.accentColor.swiftUIColor)
//          .frame(width: 44.0, height: 44.0)
//          .background(.thinMaterial)
//          .clipShape(Circle())
//          .overlay(Circle().strokeBorder(.separator, lineWidth: 1 / UIScreen.main.nativeScale))
//          .offset(x: callToActionHorizontalOffset, y: -13)
//          .zIndex(1)
//        }
      
//      else if isTransformable {
//          Button {
//            //          withAnimation(.bouncy) {
//            //            if isTransformed != nil {
//            //              isTransformed?.toggle()
//            //            } else {
//            isTransformedInternal.toggle()
//            //            }
//            //          }
//          } label: {
//            if let iconName = callToActionIconName {
//              Image(systemName: iconName)
//                .fontWeight(.semibold)
//            }
//          }
//          .tint(DesignComponentsAsset.accentColor.swiftUIColor)
//          .frame(width: 44.0, height: 44.0)
//          .background(.thinMaterial)
//          .clipShape(Circle())
//          .overlay(Circle().strokeBorder(.separator, lineWidth: 1 / UIScreen.main.nativeScale))
//          .offset(x: callToActionHorizontalOffset, y: -13)
//          .zIndex(1)
//        }
      }
      .zIndex(1)
      
//      priceView
    }
  }
  
//  @ViewBuilder private var priceView: some View {
//    if shouldShowPrice {
//      HStack(spacing: 5) {
//        if let usd = usdPrice {
//          PillText("$\(usd)")
//        }
//        
//        if let foil = usdFoilPrice {
//          PillText(
//            "$\(foil)",
//            isFoil: true
//          )
//          .foregroundStyle(.black.opacity(0.8))
//        }
//        
//        if usdPrice == nil && usdFoilPrice == nil {
//          PillText("$0.00")
//        }
//      }
//      .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
//      .font(.caption)
//      .fontWeight(.medium)
//      .monospaced()
//      .padding(.bottom, 5.0)
//    }
//  }
  
  public init(
    model: Model,
    layoutConfiguration: LayoutConfiguration,
//    usdPrice: String?,
//    usdFoilPrice: String?,
//    shouldShowPrice: Bool = true,
    callToActionIconName: String?,
    callToActionHorizontalOffset: CGFloat = 5.0
  ) {
    self.model = model
    self.layoutConfiguration = layoutConfiguration
//    self.shouldShowPrice = shouldShowPrice
//    self.usdPrice = usdPrice
//    self.usdFoilPrice = usdFoilPrice
//    self.callToActionIconName = callToActionIconName
    self.callToActionHorizontalOffset = callToActionHorizontalOffset
  }
}
