import ScryfallKit
import SwiftUI
import Networking

public struct CardView: View {
  public enum ShadowConfiguration {
    case `default`
    
    case custom(
      color: Color,
      radius: CGFloat,
      offset: CGPoint
    )
    
    var color: Color {
      switch self {
      case .default:
        return Color(.sRGBLinear, white: 0, opacity: 0.33)
        
      case let .custom(color, _, _):
        return color
      }
    }
    
    var radius: CGFloat {
      switch self {
      case .default:
        return 21.0
        
      case let .custom(_, radius, _):
        return radius
      }
    }
    
    var offset: CGPoint {
      switch self {
      case .default:
        return CGPoint(x: 0, y: 10)
        
      case let .custom(_, _, offset):
        return offset
      }
    }
  }
  
  public enum Action: Equatable {
    case toggledFaceDirection
  }
  
  public enum AccessoryInfo {
    case hidden
    case display(usdFoil: String?, usd: String?)
    case displaySet(String, usdFoil: String?, usd: String?)
  }
  
  public struct LayoutConfiguration {
    public enum Rotation {
      case landscape
      case portrait
      
      public var ratio: CGFloat {
        switch self {
        case .landscape:
          return MagicCardImageRatio.heightToWidth.rawValue
          
        case .portrait:
          return MagicCardImageRatio.widthToHeight.rawValue
        }
      }
    }
    
    public let rotation: Rotation
    public let size: CGSize
    public let cornerRadius: CGFloat
    
    public init(rotation: Rotation, maxWidth: CGFloat) {
      self.rotation = rotation
      let imageHeight = (maxWidth / rotation.ratio).rounded()
      size = CGSize(width: maxWidth, height: imageHeight)
      cornerRadius = 5 / 100 * (rotation == .landscape ? size.height : size.width)
    }
  }
  
  private let shadowConfiguration: ShadowConfiguration?
  private let layoutConfiguration: LayoutConfiguration
  private let callToActionHorizontalOffset: CGFloat
  private let displayableCard: DisplayableCardImage
  private let accessoryInfo: AccessoryInfo
  private let send: ((Action) -> Void)?
  @State private var isImageLoaded: Bool = false
  
  @Environment(\.displayScale) private var displayScale
  private var strokeScale: CGFloat { max(displayScale, 1) }
  
  public var body: some View {
    VStack(spacing: 5.0) {
      ZStack(alignment: .trailing) {
        switch displayableCard {
        case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName, id):
          transformableCardView(
            direction: direction,
            frontImageURL: frontImageURL,
            backImageURL: backImageURL,
            callToActionIconName: callToActionIconName,
            id: id
          )
          
        case let .flippable(direction, displayingImageURL, callToActionIconName, id):
          flippableCardView(
            direction: direction,
            displayingImageURL: displayingImageURL,
            callToActionIconName: callToActionIconName,
            id: id
          )
          
        case let .single(displayingImageURL, id):
          CardRemoteImageView(
            url: displayingImageURL,
            isLandscape: layoutConfiguration.rotation == .landscape,
            isTransformed: false,
            size: layoutConfiguration.size,
            id: id,
            isImageLoaded: $isImageLoaded
          )
          .ifLet(
            shadowConfiguration,
            transform: { view, value in
              view.shadow(
                color: value.color,
                radius: value.radius,
                x: value.offset.x,
                y: value.offset.y
              )
            }
          )
        }
      }
      .zIndex(1)
      
      accessoryView
        .zIndex(0)
        .redacted(reason: isImageLoaded ? [] : .placeholder)
    }
  }
  
  @ContentBuilder private func transformableCardView(
    direction: MagicCardFaceDirection,
    frontImageURL: URL,
    backImageURL: URL,
    callToActionIconName: String,
    id: String
  ) -> some View {
    CardRemoteImageView(
      url: backImageURL,
      isLandscape: layoutConfiguration.rotation == .landscape,
      isTransformed: true,
      size: layoutConfiguration.size,
      id: id,
      isImageLoaded: $isImageLoaded
    )
    .ifLet(
      shadowConfiguration,
      transform: { view, value in
        view.shadow(
          color: value.color,
          radius: value.radius,
          x: value.offset.x,
          y: value.offset.y
        )
      }
    )
    .opacity(direction == .back ? 1 : 0)
    .rotation3DEffect(.degrees(direction == .back ? 180 : 0), axis: (x: 0, y: 1, z: 0))
    .zIndex(direction == .back ? 2 : 1)
    .animation(.bouncy, value: direction)
    
    CardRemoteImageView(
      url: frontImageURL,
      isLandscape: layoutConfiguration.rotation == .landscape,
      isTransformed: false,
      size: layoutConfiguration.size,
      id: id,
      isImageLoaded: $isImageLoaded
    )
    .ifLet(
      shadowConfiguration,
      transform: { view, value in
        view.shadow(
          color: value.color,
          radius: value.radius,
          x: value.offset.x,
          y: value.offset.y
        )
      }
    )
    .opacity(direction == .front ? 1 : 0)
    .rotation3DEffect(.degrees(direction == .front ? 0 : 180), axis: (x: 0, y: 1, z: 0))
    .zIndex(direction == .front ? 2 : 1)
    .animation(.bouncy, value: direction)
    
    Button {
      send?(.toggledFaceDirection)
    } label: {
      Image(systemName: callToActionIconName).fontWeight(.semibold)
    }
    .tint(DesignComponentsAsset.accentColor.swiftUIColor)
    .frame(width: 44.0, height: 44.0)
    .glassEffect(.regular.interactive(true))
    .offset(x: callToActionHorizontalOffset, y: -13)
    .zIndex(3)
  }
  
  @ContentBuilder private func flippableCardView(
    direction: MagicCardFaceDirection,
    displayingImageURL: URL,
    callToActionIconName: String,
    id: String
  ) -> some View {
    CardRemoteImageView(
      url: displayingImageURL,
      isLandscape: layoutConfiguration.rotation == .landscape,
      isTransformed: false,
      size: layoutConfiguration.size,
      id: id,
      isImageLoaded: $isImageLoaded
    )
    .ifLet(
      shadowConfiguration,
      transform: { view, value in
        view.shadow(
          color: value.color,
          radius: value.radius,
          x: value.offset.x,
          y: value.offset.y
        )
      }
    )
    .rotationEffect(.degrees(direction == .front ? 0 : 180))
    .zIndex(2)
    .animation(.bouncy, value: direction)
    
    Button { send?(.toggledFaceDirection) } label: { Image(systemName: callToActionIconName).fontWeight(.semibold) }
      .tint(DesignComponentsAsset.accentColor.swiftUIColor)
      .frame(width: 44.0, height: 44.0)
      .glassEffect()
      .clipShape(Circle())
      .overlay(Circle().strokeBorder(.separator, lineWidth: 1 / strokeScale))
      .offset(x: callToActionHorizontalOffset, y: -13)
      .zIndex(3)
  }
  
  @ContentBuilder private var accessoryView: some View {
    switch accessoryInfo {
    case let .display(foilPrice, usdPrice):
      Text("$\(usdPrice ?? foilPrice ?? "0.00")")
        .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
        .font(.system(size: 11.0)).fontWeight(.medium).fontWidth(.compressed).monospaced().frame(height: 15)
      
    case let .displaySet(set, usdFoilPrice, usdPrice):
      VStack(alignment: .center, spacing: 5.0) {
        Text(set).font(.caption).multilineTextAlignment(.center).lineLimit(1).foregroundStyle(.secondary)
        HStack(spacing: 5) {
          if let usdPrice { PillText("$\(usdPrice)") }
          if let usdFoilPrice { PillText("$\(usdFoilPrice)", isFoil: true).foregroundStyle(.black.opacity(0.8)) }
          if usdPrice == nil && usdFoilPrice == nil { PillText("$0.00").unavailable(true) }
        }
        .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
        .font(.caption).fontWeight(.medium).monospaced().frame(height: 15)
      }
      
    case .hidden:
      EmptyView()
    }
  }
  
  public init?(
    displayableCard: DisplayableCardImage?,
    layoutConfiguration: LayoutConfiguration,
    callToActionHorizontalOffset: CGFloat = 5.0,
    priceVisibility: AccessoryInfo,
    shadowConfiguration: ShadowConfiguration? = nil,
    send: ((Action) -> Void)? = nil
  ) {
    guard let displayableCard else { return nil }
    self.displayableCard = displayableCard
    self.accessoryInfo = priceVisibility
    self.layoutConfiguration = layoutConfiguration
    self.callToActionHorizontalOffset = callToActionHorizontalOffset
    self.shadowConfiguration = shadowConfiguration
    self.send = send
  }
}
