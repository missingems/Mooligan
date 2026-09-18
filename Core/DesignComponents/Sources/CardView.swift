import ScryfallKit
import SwiftUI
import Networking

public struct CardView<Surface: ViewModifier & Equatable>: View, Equatable {
  /// Compared on what it draws. `send` is a closure, which is never equal, and only reports a tap
  /// to a store that outlives the comparison. Without this every store write re-ran every visible
  /// card in a grid, image and all.
  nonisolated public static func == (lhs: CardView, rhs: CardView) -> Bool {
    lhs.displayableCard == rhs.displayableCard
      && lhs.layoutConfiguration == rhs.layoutConfiguration
      && lhs.callToActionHorizontalOffset == rhs.callToActionHorizontalOffset
      && lhs.accessoryInfo == rhs.accessoryInfo
      && lhs.shadowConfiguration == rhs.shadowConfiguration
      && lhs.downsampleWidth == rhs.downsampleWidth
      // SwiftUI takes this comparison as the whole truth about the view, so a surface left out here
      // is a surface that never updates: its fade would be stuck at whatever value the card was
      // built with.
      && lhs.surface == rhs.surface
  }

  public enum ShadowConfiguration: Equatable, Sendable {
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
  
  public enum AccessoryInfo: Equatable, Sendable {
    case hidden
    case display(usdFoil: String?, usd: String?)
    case displaySet(String, usdFoil: String?, usd: String?)
  }
  
  private let shadowConfiguration: ShadowConfiguration?
  private let layoutConfiguration: CardLayoutConfiguration
  private let surface: Surface
  private let callToActionHorizontalOffset: CGFloat
  private let displayableCard: DisplayableCardImage
  private let accessoryInfo: AccessoryInfo
  private let send: ((Action) -> Void)?
  private let downsampleWidth: CGFloat?
  
  @State private var isImageLoaded: Bool = false
  @Environment(\.displayScale) private var displayScale
  private var strokeScale: CGFloat { max(displayScale, 1) }
  
  public var body: some View {
    VStack(spacing: 5.0) {
      mainCardContent
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
        downsampleWidth: downsampleWidth,
        isImageLoaded: $isImageLoaded
      )
      .modifier(surface)
      .rotation3DEffect(.degrees(direction == .front ? 0 : 180), axis: (x: 0, y: 1, z: 0))
      .animation(.bouncy, value: direction)
      .overlay(alignment: .trailing) {
        // In the hierarchy only once there is an image to act on. Hidden with an opacity, the glass
        // capsule was still laid out on every scroll frame of every row it sat in.
        if isImageLoaded {
          callToActionButton(iconName: callToActionIconName)
        }
      }
      
    case let .flippable(direction, displayingImageURL, callToActionIconName, id):
      CardRemoteImageView(
        url: displayingImageURL,
        isLandscape: layoutConfiguration.rotation == .landscape,
        isTransformed: false,
        size: layoutConfiguration.size,
        id: id,
        downsampleWidth: downsampleWidth,
        isImageLoaded: $isImageLoaded
      )
      .modifier(surface)
      .rotationEffect(.degrees(direction == .front ? 0 : 180))
      .animation(.bouncy, value: direction)
      .overlay(alignment: .trailing) {
        // In the hierarchy only once there is an image to act on. Hidden with an opacity, the glass
        // capsule was still laid out on every scroll frame of every row it sat in.
        if isImageLoaded {
          callToActionButton(iconName: callToActionIconName)
        }
      }
      
    case let .single(displayingImageURL, id):
      CardRemoteImageView(
        url: displayingImageURL,
        isLandscape: layoutConfiguration.rotation == .landscape,
        isTransformed: false,
        size: layoutConfiguration.size,
        id: id,
        downsampleWidth: downsampleWidth,
        isImageLoaded: $isImageLoaded
      )
      .modifier(surface)
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
    layoutConfiguration: CardLayoutConfiguration,
    surface: Surface,
    callToActionHorizontalOffset: CGFloat = 5.0,
    priceVisibility: AccessoryInfo,
    shadowConfiguration: ShadowConfiguration? = nil,
    downsampleWidth: CGFloat? = nil,
    send: ((Action) -> Void)? = nil
  ) {
    guard let displayableCard else { return nil }
    self.displayableCard = displayableCard
    self.surface = surface
    self.accessoryInfo = priceVisibility
    self.layoutConfiguration = layoutConfiguration
    self.callToActionHorizontalOffset = callToActionHorizontalOffset
    self.shadowConfiguration = shadowConfiguration
    self.downsampleWidth = downsampleWidth
    self.send = send
  }
}

public extension CardView where Surface == EmptyCardSurface {
  init?(
    displayableCard: DisplayableCardImage?,
    layoutConfiguration: CardLayoutConfiguration,
    callToActionHorizontalOffset: CGFloat = 5.0,
    priceVisibility: AccessoryInfo,
    shadowConfiguration: ShadowConfiguration? = nil,
    downsampleWidth: CGFloat? = nil,
    send: ((Action) -> Void)? = nil
  ) {
    self.init(
      displayableCard: displayableCard,
      layoutConfiguration: layoutConfiguration,
      surface: EmptyCardSurface(),
      callToActionHorizontalOffset: callToActionHorizontalOffset,
      priceVisibility: priceVisibility,
      shadowConfiguration: shadowConfiguration,
      downsampleWidth: downsampleWidth,
      send: send
    )
  }
}
