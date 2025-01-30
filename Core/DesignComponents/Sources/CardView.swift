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
  private let displayableCard: DisplayableCardImage
  private let priceVisibility: PriceVisibility
  private let send: ((Action) -> Void)?
  private let namespace: Namespace.ID
  @State private var localDisplayableCard: DisplayableCardImage?
  
  public var body: some View {
    VStack(spacing: 5) {
      ZStack(alignment: .trailing) {
        switch localDisplayableCard ?? displayableCard {
        case let .transformable(
          direction,
          frontImageURL,
          backImageURL,
          callToActionIconName,
          id
        ):
          Group {
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
          }
          .matchedTransitionSource(id: id, in: namespace)
          
          Button {
            if let send {
              send(.toggledFaceDirection)
            } else {
              localDisplayableCard = .transformable(
                direction: direction.toggled(),
                frontImageURL: frontImageURL,
                backImageURL: backImageURL,
                callToActionIconName: callToActionIconName,
                id: id
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
          
        case let .flippable(direction, displayingImageURL, callToActionIconName, id):
          flippableCardView(
            direction: direction,
            displayingImageURL: displayingImageURL,
            callToActionIconName: callToActionIconName,
            id: id
          )
          .frame(width: layoutConfiguration.size.width, height: layoutConfiguration.size.height, alignment: .center)
          
        case let .single(displayingImageURL, id):
          CardRemoteImageView(
            url: displayingImageURL,
            isLandscape: layoutConfiguration.rotation == .landscape,
            isTransformed: false,
            size: layoutConfiguration.size
          )
          .matchedTransitionSource(id: id, in: namespace)
          .frame(width: layoutConfiguration.size.width, height: layoutConfiguration.size.height, alignment: .center)
        }
      }
      
      priceView
    }
  }
  
  @ViewBuilder private func flippableCardView(
    direction: MagicCardFaceDirection,
    displayingImageURL: URL,
    callToActionIconName: String,
    id: UUID
  ) -> some View {
    CardRemoteImageView(
      url: displayingImageURL,
      isLandscape: layoutConfiguration.rotation == .landscape,
      isTransformed: false,
      size: layoutConfiguration.size
    )
    .matchedTransitionSource(id: id, in: namespace)
    .rotationEffect(.degrees(direction == .front ? 0 : 180))
    .zIndex(2)
    .transaction { transaction in
      transaction.animation = .bouncy
    }
    
    Button {
      if let send {
        send(.toggledFaceDirection)
      } else {
        localDisplayableCard = .flippable(
          direction: direction.toggled(),
          displayingImageURL: displayingImageURL,
          callToActionIconName: callToActionIconName,
          id: id
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
        if let usdPrice {
          PillText("$\(usdPrice)")
        }
        
        if let usdFoilPrice {
          PillText("$\(usdFoilPrice)", isFoil: true)
            .foregroundStyle(.black.opacity(0.8))
        }
        
        if usdPrice == nil && usdFoilPrice == nil {
          PillText("$0.00").unavailable(true)
        }
      }
      .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
      .font(.caption)
      .fontWeight(.medium)
      .monospaced()
      .frame(height: 21.0)
    }
  }
  
  public init(
    displayableCard: DisplayableCardImage,
    layoutConfiguration: LayoutConfiguration,
    callToActionHorizontalOffset: CGFloat = 5.0,
    priceVisibility: PriceVisibility,
    namespace: Namespace.ID,
    send: ((Action) -> Void)? = nil
  ) {
    self.displayableCard = displayableCard
    self.priceVisibility = priceVisibility
    
    if send == nil {
      localDisplayableCard = displayableCard
    }
    
    self.layoutConfiguration = layoutConfiguration
    self.callToActionHorizontalOffset = callToActionHorizontalOffset
    self.namespace = namespace
    self.send = send
  }
  
  public init?(
    displayableCard: DisplayableCardImage?,
    layoutConfiguration: LayoutConfiguration,
    callToActionHorizontalOffset: CGFloat = 5.0,
    priceVisibility: PriceVisibility,
    namespace: Namespace.ID,
    send: ((Action) -> Void)? = nil
  ) {
    guard let displayableCard else {
      return nil
    }
    
    self.displayableCard = displayableCard
    self.priceVisibility = priceVisibility
    
    if send == nil {
      localDisplayableCard = displayableCard
    }
    
    self.layoutConfiguration = layoutConfiguration
    self.callToActionHorizontalOffset = callToActionHorizontalOffset
    self.namespace = namespace
    self.send = send
  }
}
