import ScryfallKit
import SwiftUI
import Networking

/// `Equatable` so that a parent rebuilding does not become a card rebuilding.
///
/// A card view is a decoded image behind a `clipShape` and a stroked overlay,
/// and on a foil it is a Metal shader as well. Without an `==` SwiftUI compares
/// this by its stored properties, and the `send` closure it carries is never
/// equal to another closure — so every re-run of an enclosing body rebuilt the
/// card. Both grids and the card detail rebuild their bodies for reasons that
/// have nothing to do with any individual card.
public struct CardView: View, Equatable {
  /// Compares what is drawn. `send` is deliberately excluded: it is a closure,
  /// which is never equal, and every caller's does the same thing for the same
  /// card — reports that its face was tapped.
  public nonisolated static func == (lhs: CardView, rhs: CardView) -> Bool {
    lhs.displayableCard == rhs.displayableCard
      && lhs.layoutConfiguration == rhs.layoutConfiguration
      && lhs.accessoryInfo == rhs.accessoryInfo
      && lhs.shadowConfiguration == rhs.shadowConfiguration
      && lhs.callToActionHorizontalOffset == rhs.callToActionHorizontalOffset
      && lhs.isFoilOnly == rhs.isFoilOnly
      && lhs.isFoilAnimated == rhs.isFoilAnimated
  }

  public enum ShadowConfiguration: Equatable {
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
  
  public enum AccessoryInfo: Equatable {
    case hidden
    case display(usdFoil: String?, usd: String?)
    case displaySet(String, usdFoil: String?, usd: String?)
  }
  
  public struct LayoutConfiguration: Equatable {
    public enum Rotation: Equatable {
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
  private let isFoilOnly: Bool
  private let isFoilAnimated: Bool
  
  @State private var isImageLoaded: Bool = false
  @Environment(\.displayScale) private var displayScale
  private var strokeScale: CGFloat { max(displayScale, 1) }
  
  public var body: some View {
    VStack(spacing: 5.0) {
      if isFoilOnly {
        mainCardContent.holographicFoil(intensity: 0.34, isAnimated: isFoilAnimated)
      } else {
        mainCardContent
      }
    }
    .geometryGroup()
  }
  
  @ContentBuilder private var mainCardContent: some View {
    switch displayableCard {
    case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName, id):
      CardRemoteImageView(
        url: direction == .front ? frontImageURL : backImageURL,
        isLandscape: layoutConfiguration.rotation == .landscape,
        isTransformed: direction == .front ? false : true,
        size: layoutConfiguration.size,
        id: id,
        isImageLoaded: $isImageLoaded
      )
      .rotation3DEffect(.degrees(direction == .front ? 0 : 180), axis: (x: 0, y: 1, z: 0))
      .animation(.bouncy, value: direction)
      .overlay(alignment: .trailing) {
        callToActionButton(iconName: callToActionIconName)
      }
      
    case let .flippable(direction, displayingImageURL, callToActionIconName, id):
      CardRemoteImageView(
        url: displayingImageURL,
        isLandscape: layoutConfiguration.rotation == .landscape,
        isTransformed: false,
        size: layoutConfiguration.size,
        id: id,
        isImageLoaded: $isImageLoaded
      )
      .rotationEffect(.degrees(direction == .front ? 0 : 180))
      .animation(.bouncy, value: direction)
      .overlay(alignment: .trailing) {
        callToActionButton(iconName: callToActionIconName)
      }
      
    case let .single(displayingImageURL, id):
      CardRemoteImageView(
        url: displayingImageURL,
        isLandscape: layoutConfiguration.rotation == .landscape,
        isTransformed: false,
        size: layoutConfiguration.size,
        id: id,
        isImageLoaded: $isImageLoaded
      )
    }
  }
  
  @ContentBuilder private func callToActionButton(iconName: String) -> some View {
    Image(systemName: iconName)
      .fontWeight(.semibold)
      .onTapGesture {
        send?(.toggledFaceDirection)
      }
      .tint(DesignComponentsAsset.accentColor.swiftUIColor)
      .frame(width: 44.0, height: 44.0)
      .glassEffect(.regular.interactive())
      .offset(x: callToActionHorizontalOffset, y: -13)
      .opacity(isImageLoaded ? 1 : 0)
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
    isFoilOnly: Bool = false,
    isFoilAnimated: Bool = true,
    send: ((Action) -> Void)? = nil
  ) {
    guard let displayableCard else { return nil }
    self.displayableCard = displayableCard
    self.isFoilOnly = isFoilOnly
    self.isFoilAnimated = isFoilAnimated
    self.accessoryInfo = priceVisibility
    self.layoutConfiguration = layoutConfiguration
    self.callToActionHorizontalOffset = callToActionHorizontalOffset
    self.shadowConfiguration = shadowConfiguration
    self.send = send
  }
}
