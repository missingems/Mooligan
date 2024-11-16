import Networking
import SwiftUI

public struct CardView: View {
  public struct Configuration {
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
      
      var ratio: CGFloat {
        switch self {
        case .landscape: return MagicCardImageRatio.widthToHeight.rawValue
        case .portrait: return MagicCardImageRatio.heightToWidth.rawValue
        }
      }
    }
    
    let rotation: Rotation
    let layout: Layout
    
    public init(rotation: Rotation, layout: Layout) {
      self.rotation = rotation
      self.layout = layout
    }
  }
  
  let card: any MagicCard
  let imageURL: URL?
  let backImageURL: URL?
  let configuration: Configuration
  let shouldShowPrice: Bool
  
  @State private var isFlipped = false
  @State private var isRotated = false
  
  public var body: some View {
    VStack(spacing: 5) {
      ZStack(alignment: .trailing) {
        if let imageURL {
          switch configuration.layout {
          case let .fixedWidth(width):
            let width = width.rounded()
            let height = (width * configuration.rotation.ratio).rounded()
            
            if let backImageURL {
              AmbientWebImage(
                url: backImageURL,
                cornerRadius: (5 / 100 * width).rounded(),
                rotation: configuration.rotation.degrees,
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
              rotation: configuration.rotation.degrees,
              isFlipped: false,
              size: CGSize(
                width: width.rounded(),
                height: (width * configuration.rotation.ratio).rounded()
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
                rotation: configuration.rotation.degrees,
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
              rotation: configuration.rotation.degrees,
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
        if let usd = card.getPrices().usd {
          PillText("$\(usd)")
        }
        
        if let foil = card.getPrices().usdFoil {
          PillText(
            "$\(foil)",
            isFoil: true
          )
          .foregroundStyle(.black.opacity(0.8))
        }
        
        if card.getPrices().usd == nil && card.getPrices().usdFoil == nil {
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
    if card.isFlippable {
      Button {
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
    } else if card.isRotatable {
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
  
  public init(
    card: any MagicCard,
    configuration: Configuration,
    shouldShowPrice: Bool = true
  ) {
    self.card = card
    self.imageURL = card.getImageURL()
    
    if card.isFlippable {
      self.backImageURL = card.getCardFace(for: .back).getImageURL()
    } else {
      self.backImageURL = nil
    }
    
    self.configuration = configuration
    self.shouldShowPrice = shouldShowPrice
  }
}
