import SwiftUI
import Networking

public struct CardView<Card: MagicCard>: View {
  public enum Model: Identifiable, Equatable {
    public enum FaceDirection {
      case front
      case back
      
      var id: String {
        switch self {
        case .front: return "front"
        case .back: return "back"
        }
      }
    }
    
    case transformable(direction: FaceDirection, frontImageURL: URL, backImageURL: URL, callToActionIconName: String)
    case flippable(displayingImageURL: URL, callToActionIconName: String)
    case single(displayingImageURL: URL)
    
    public var id: String {
      switch self {
      case let .transformable(direction, frontImageURL, backImageURL, _):
        return direction.id + frontImageURL.absoluteString + backImageURL.absoluteString
        
      case let .flippable(displayingImageURL, _):
        return displayingImageURL.absoluteString
        
      case let .single(displayingImageURL):
        return displayingImageURL.absoluteString
      }
    }
    
    public init?(_ card: Card) {
      if card.isTransformable, let frontImageURL = card.getCardFace(for: .front).getImageURL(), let backImageURL = card.getCardFace(for: .back).getImageURL(), let callToActionIconName = card.getLayout().value.callToActionIconName {
        self = .transformable(direction: .front, frontImageURL: frontImageURL, backImageURL: backImageURL, callToActionIconName: callToActionIconName)
      } else if card.isFlippable, let imageURL = card.getImageURL(), let callToActionIconName = card.getLayout().value.callToActionIconName {
        self = .flippable(displayingImageURL: imageURL, callToActionIconName: callToActionIconName)
      } else if let imageURL = card.getImageURL() {
        self = .single(displayingImageURL: imageURL)
      } else {
        return nil
      }
    }
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
  
  private let layoutConfiguration: LayoutConfiguration
  private let callToActionHorizontalOffset: CGFloat
  @State private var model: Model
  
  public var body: some View {
    VStack(spacing: 5) {
      ZStack(alignment: .trailing) {
        switch model {
        case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName):
          AmbientWebImage(
            url: backImageURL,
            cornerRadius: layoutConfiguration.cornerRadius.rounded(),
            rotation: layoutConfiguration.rotation.degrees,
            isTransformed: true,
            size: layoutConfiguration.size
          )
          .frame(width: layoutConfiguration.size.width, height: layoutConfiguration.size.height, alignment: .center)
          .opacity(direction == .back ? 1 : 0)
          .rotation3DEffect(.degrees(direction == .back ? 180 : 0), axis: (x: 0, y: 1, z: 0))
          .zIndex(direction == .back ? 1 : 0)
          .animation(.bouncy, value: model)
          
          AmbientWebImage(
            url: frontImageURL,
            cornerRadius: layoutConfiguration.cornerRadius.rounded(),
            rotation: layoutConfiguration.rotation.degrees,
            isTransformed: false,
            size: layoutConfiguration.size
          )
          .frame(width: layoutConfiguration.size.width, height: layoutConfiguration.size.height, alignment: .center)
          .opacity(direction == .front ? 1 : 0)
          .rotation3DEffect(.degrees(direction == .front ? 0 : 180), axis: (x: 0, y: 1, z: 0))
          .zIndex(direction == .front ? 1 : 0)
          .animation(.bouncy, value: model)
          
          Button {
            model = .transformable(
              direction: direction == .back ? .front : .back,
              frontImageURL: frontImageURL,
              backImageURL: backImageURL,
              callToActionIconName: callToActionIconName
            )
          } label: {
                          Image(systemName: callToActionIconName)
                            .fontWeight(.semibold)
          }
          .zIndex(2)
          
          //          Button {
          //
          //            isFlippedInternal.toggle()
          //          } label: {
          //            if let iconName = callToActionIconName {
          //              Image(systemName: iconName)
          //                .fontWeight(.semibold)
          //            }
          //          }
                    .tint(DesignComponentsAsset.accentColor.swiftUIColor)
                    .frame(width: 44.0, height: 44.0)
                    .background(.thinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.separator, lineWidth: 1 / UIScreen.main.nativeScale))
                    .offset(x: callToActionHorizontalOffset, y: -13)
                    .zIndex(1)
          
        case let .flippable(displayingImageURL):
          Text("Hello World")
          
        case let .single(displayingImageURL):
          Text("Hello World")
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
      .geometryGroup()
      
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
  
  let send: (Action) -> Void
  public init(
    model: Model,
    layoutConfiguration: LayoutConfiguration,
//    usdPrice: String?,
//    usdFoilPrice: String?,
//    shouldShowPrice: Bool = true,
    callToActionHorizontalOffset: CGFloat = 5.0,
    send: @escaping (Action) -> Void
  ) {
    self.model = model
    self.layoutConfiguration = layoutConfiguration
//    self.shouldShowPrice = shouldShowPrice
//    self.usdPrice = usdPrice
//    self.usdFoilPrice = usdFoilPrice
//    self.callToActionIconName = callToActionIconName
    self.callToActionHorizontalOffset = callToActionHorizontalOffset
    self.send = send
  }
  
  public enum Action: Equatable {
    case toggledFaceDirection(CardView<Card>.Model)
  }
}
