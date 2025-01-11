import ScryfallKit
import SwiftUI
import Networking

public struct CardView: View {
  public enum Action: Equatable {
    case toggledFaceDirection
  }
  
  public enum PriceVisibility {
    case hidden
    case display(usdFoil: String?, usd: String?)
  }
  
  public enum Mode: Equatable {
    case transformable(
      direction: MagicCardFaceDirection,
      frontImageURL: URL,
      backImageURL: URL,
      callToActionIconName: String
    )
    
    case flippable(
      direction: MagicCardFaceDirection,
      displayingImageURL: URL,
      callToActionIconName: String
    )
    
    case single(displayingImageURL: URL)
    
    public var faceDirection: MagicCardFaceDirection {
      switch self {
      case let .transformable(direction, _, _, _):
        return direction
        
      case let .flippable(direction, _, _):
        return direction
        
      case .single:
        return .front
      }
    }
    
    public init(_ card: Card) {
      if card.isTransformable,
         let frontImageURL = card.getImageURL(type: .normal, getSecondFace: false),
         let backImageURL = card.getImageURL(type: .normal, getSecondFace: true),
         let callToActionIconName = card.layout.callToActionIconName {
        self = .transformable(
          direction: .front,
          frontImageURL: frontImageURL,
          backImageURL: backImageURL,
          callToActionIconName: callToActionIconName
        )
      } else if
        card.isFlippable,
        let imageURL = card.getImageURL(type: .normal),
        let callToActionIconName = card.layout.callToActionIconName {
        self = .flippable(
          direction: .front,
          displayingImageURL: imageURL,
          callToActionIconName: callToActionIconName
        )
      } else if let imageURL = card.getImageURL(type: .normal) {
        self = .single(displayingImageURL: imageURL)
      } else {
        fatalError("Impossible state: ImageURL cannot be nil.")
      }
    }
  }
  
  public struct LayoutConfiguration {
    public enum Rotation {
      case landscape
      case portrait
      
      public var ratio: CGFloat {
        switch self {
        case .landscape: return MagicCardImageRatio.heightToWidth.rawValue
        case .portrait: return MagicCardImageRatio.widthToHeight.rawValue
        }
      }
    }
    
    public let rotation: Rotation
    public let size: CGSize
    
    public init(rotation: Rotation, maxWidth: CGFloat) {
      self.rotation = rotation
      
      let imageHeight = (maxWidth / rotation.ratio).rounded()
      size = CGSize(width: maxWidth, height: imageHeight)
    }
  }
  
  private let layoutConfiguration: LayoutConfiguration
  private let callToActionHorizontalOffset: CGFloat
  private let mode: Mode
  private let priceVisibility: PriceVisibility
  private let send: ((Action) -> Void)?
  @State private var localMode: Mode?
  
  public var body: some View {
    VStack(spacing: 5) {
      ZStack(alignment: .trailing) {
        switch localMode ?? mode {
        case let .transformable(
          direction,
          frontImageURL,
          backImageURL,
          callToActionIconName
        ):
          CardRemoteImageView(
            url: backImageURL,
            isLandscape: layoutConfiguration.rotation == .landscape,
            isTransformed: true,
            size: layoutConfiguration.size
          )
          .opacity(direction == .back ? 1 : 0)
          .rotation3DEffect(.degrees(direction == .back ? 180 : 0), axis: (x: 0, y: 1, z: 0))
          .zIndex(direction == .back ? 2 : 1)
          .transaction { transaction in
            transaction.animation = .bouncy
          }
          
          CardRemoteImageView(
            url: frontImageURL,
            isLandscape: layoutConfiguration.rotation == .landscape,
            isTransformed: false,
            size: layoutConfiguration.size
          )
          .opacity(direction == .front ? 1 : 0)
          .rotation3DEffect(.degrees(direction == .front ? 0 : 180), axis: (x: 0, y: 1, z: 0))
          .zIndex(direction == .front ? 2 : 1)
          .transaction { transaction in
            transaction.animation = .bouncy
          }
          
          Button {
            if let send {
              send(.toggledFaceDirection)
            } else {
              localMode = .transformable(
                direction: direction.toggled(),
                frontImageURL: frontImageURL,
                backImageURL: backImageURL,
                callToActionIconName: callToActionIconName
              )
            }
          } label: {
            Image(systemName: callToActionIconName).fontWeight(.semibold)
          }
          .tint(DesignComponentsAsset.accentColor.swiftUIColor)
          .frame(width: 44.0, height: 44.0)
          .background(.thinMaterial)
          .clipShape(Circle())
          .overlay(Circle().strokeBorder(.separator, lineWidth: 1 / UIScreen.main.nativeScale))
          .offset(x: callToActionHorizontalOffset, y: -13)
          .zIndex(3)
          
        case let .flippable(direction, displayingImageURL, callToActionIconName):
          flippableCardView(
            direction: direction,
            displayingImageURL: displayingImageURL,
            callToActionIconName: callToActionIconName
          )
          .frame(width: layoutConfiguration.size.width, height: layoutConfiguration.size.height, alignment: .center)
          
        case let .single(displayingImageURL):
          CardRemoteImageView(
            url: displayingImageURL,
            isLandscape: layoutConfiguration.rotation == .landscape,
            isTransformed: false,
            size: layoutConfiguration.size
          )
          .frame(width: layoutConfiguration.size.width, height: layoutConfiguration.size.height, alignment: .center)
        }
      }
      .zIndex(1)
      
      priceView
        .zIndex(0)
    }
  }
  
  @ViewBuilder private func flippableCardView(
    direction: MagicCardFaceDirection,
    displayingImageURL: URL,
    callToActionIconName: String
  ) -> some View {
    CardRemoteImageView(
      url: displayingImageURL,
      isLandscape: layoutConfiguration.rotation == .landscape,
      isTransformed: false,
      size: layoutConfiguration.size
    )
    .rotationEffect(.degrees(direction == .front ? 0 : 180))
    .zIndex(2)
    .transaction { transaction in
      transaction.animation = .bouncy
    }
    
    Button {
      if let send {
        send(.toggledFaceDirection)
      } else {
        localMode = .flippable(
          direction: direction.toggled(),
          displayingImageURL: displayingImageURL,
          callToActionIconName: callToActionIconName
        )
      }
    } label: {
      Image(systemName: callToActionIconName).fontWeight(.semibold)
    }
    .tint(DesignComponentsAsset.accentColor.swiftUIColor)
    .frame(width: 44.0, height: 44.0)
    .background(.thinMaterial)
    .clipShape(Circle())
    .overlay(Circle().strokeBorder(.separator, lineWidth: 1 / UIScreen.main.nativeScale))
    .offset(x: callToActionHorizontalOffset, y: -13)
    .zIndex(3)
  }
  
  @ViewBuilder private var priceView: some View {
    if case let .display(usdFoilPrice, usdPrice) = priceVisibility {
      HStack(spacing: 5) {
        if let usd = usdPrice {
          PillText("$\(usd)")
        }
        
        if let foil = usdFoilPrice {
          PillText("$\(foil)", isFoil: true)
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
    }
  }
  
  public init(
    card: Card,
    layoutConfiguration: LayoutConfiguration,
    callToActionHorizontalOffset: CGFloat = 5.0,
    priceVisibility: PriceVisibility,
    send: ((Action) -> Void)? = nil
  ) {
    mode = Mode(card)
    self.priceVisibility = priceVisibility
    
    if send == nil {
      localMode = mode
    }
    
    self.layoutConfiguration = layoutConfiguration
    self.callToActionHorizontalOffset = callToActionHorizontalOffset
    self.send = send
  }
  
  public init?(
    mode: Mode?,
    layoutConfiguration: LayoutConfiguration,
    callToActionHorizontalOffset: CGFloat = 5.0,
    priceVisibility: PriceVisibility,
    send: ((Action) -> Void)? = nil
  ) {
    guard let mode else {
      return nil
    }
    
    self.mode = mode
    self.priceVisibility = priceVisibility
    
    if send == nil {
      localMode = mode
    }
    
    self.layoutConfiguration = layoutConfiguration
    self.callToActionHorizontalOffset = callToActionHorizontalOffset
    self.send = send
  }
}
