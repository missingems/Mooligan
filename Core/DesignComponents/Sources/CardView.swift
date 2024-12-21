import SwiftUI
import Networking

public struct CardView<Card: MagicCard>: View {
  public enum Action: Equatable {
    case toggledFaceDirection
  }
  
  public enum PriceVisibility {
    case hidden
    case display(usdFoil: String?, usd: String?)
  }
  
  public enum Mode: Identifiable, Equatable {
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
    
    public var id: String {
      switch self {
      case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName):
        return direction.id + frontImageURL.absoluteString + backImageURL.absoluteString + callToActionIconName
        
      case let .flippable(direction, displayingImageURL, callToActionIconName):
        return direction.id + displayingImageURL.absoluteString + callToActionIconName
        
      case let .single(displayingImageURL):
        return displayingImageURL.absoluteString
      }
    }
    
    public init?(_ card: Card) {
      if card.isTransformable,
          let frontImageURL = card.getCardFace(for: .front).getImageURL(),
          let backImageURL = card.getCardFace(for: .back).getImageURL(),
          let callToActionIconName = card.getLayout().value.callToActionIconName {
        self = .transformable(
          direction: .front,
          frontImageURL: frontImageURL,
          backImageURL: backImageURL,
          callToActionIconName: callToActionIconName
        )
      } else if
        card.isFlippable,
        let imageURL = card.getImageURL(),
        let callToActionIconName = card.getLayout().value.callToActionIconName {
        self = .flippable(
          direction: .front,
          displayingImageURL: imageURL,
          callToActionIconName: callToActionIconName
        )
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
    public let cornerRadius: CGFloat
    public let size: CGSize?
    
    public init(rotation: Rotation, maxWidth: CGFloat?) {
      self.rotation = rotation
      
      if let maxWidth {
        let imageHeight = maxWidth / rotation.ratio
        size = CGSize(width: maxWidth, height: imageHeight)
      } else {
        size = nil
      }
      
      cornerRadius = 9.0
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
          AmbientWebImage(
            url: backImageURL,
            cornerRadius: layoutConfiguration.cornerRadius,
            rotation: layoutConfiguration.rotation.degrees,
            isTransformed: true,
            size: layoutConfiguration.size
          )
          .opacity(direction == .back ? 1 : 0)
          .rotation3DEffect(.degrees(direction == .back ? 180 : 0), axis: (x: 0, y: 1, z: 0))
          .zIndex(direction == .back ? 2 : 1)
          .animation(.bouncy, value: localMode)
          
          AmbientWebImage(
            url: frontImageURL,
            cornerRadius: layoutConfiguration.cornerRadius,
            rotation: layoutConfiguration.rotation.degrees,
            isTransformed: false,
            size: layoutConfiguration.size
          )
          .opacity(direction == .front ? 1 : 0)
          .rotation3DEffect(.degrees(direction == .front ? 0 : 180), axis: (x: 0, y: 1, z: 0))
          .zIndex(direction == .front ? 2 : 1)
          
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
          
        case let .single(displayingImageURL):
          AmbientWebImage(
            url: displayingImageURL,
            cornerRadius: layoutConfiguration.cornerRadius,
            rotation: layoutConfiguration.rotation.degrees,
            isTransformed: false,
            size: layoutConfiguration.size
          )
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
    AmbientWebImage(
      url: displayingImageURL,
      cornerRadius: layoutConfiguration.cornerRadius,
      rotation: layoutConfiguration.rotation.degrees,
      isTransformed: false,
      size: layoutConfiguration.size
    )
    .rotationEffect(.degrees(direction == .front ? 0 : 180))
    .zIndex(2)
    .animation(.bouncy, value: direction)
    
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
      .padding(.bottom, 5.0)
    }
  }
  
  public init?(
    card: Card,
    layoutConfiguration: LayoutConfiguration,
    callToActionHorizontalOffset: CGFloat = 5.0,
    priceVisibility: PriceVisibility,
    send: ((Action) -> Void)? = nil
  ) {
    guard let mode = Mode(card) else {
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
