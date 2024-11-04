import Networking
import SwiftUI

public struct CardView: View {
  public enum LayoutConfiguration: Sendable, Equatable {
    case fixedWidth(CGFloat)
    case fixedSize(CGSize)
    case flexible
  }
  
  let card: any MagicCard
  @State var displayingImageURL: URL
  @State var displayingFace: any MagicCardFace {
    didSet {
      if let url = displayingFace.getImageURL() {
        displayingImageURL = url
      }
    }
  }
  let layoutConfiguration: LayoutConfiguration
  let shouldShowPrice: Bool
  
  @State private var isFlipped = false {
    didSet {
      if isFlipped {
        displayingFace = card.getCardFace(for: .back)
      } else {
        displayingFace = card.getCardFace(for: .front)
      }
    }
  }
  
  @State private var isRotated = false
  
  public var body: some View {
    VStack(spacing: 5) {
      ZStack(alignment: .trailing) {
        Group {
          switch layoutConfiguration {
          case let .fixedSize(size):
            AmbientWebImage(
              url: displayingImageURL,
              cornerRadius: 5 / 100 * size.width,
              isFlipped: isFlipped,
              size: CGSize(
                width: size.width,
                height: size.height
              )
            )
            .frame(
              width: size.width,
              height: size.height,
              alignment: .center
            )
            
          case let .fixedWidth(width):
            AmbientWebImage(
              url: displayingImageURL,
              cornerRadius: 5 / 100 * width,
              isFlipped: isFlipped,
              size: CGSize(
                width: width,
                height: width * MagicCardImageRatio.heightToWidth.rawValue
              )
            )
            .frame(
              width: width,
              height: width * MagicCardImageRatio.heightToWidth.rawValue,
              alignment: .center
            )
            
          case .flexible:
            AmbientWebImage(url: displayingImageURL)
          }
        }
        .rotationEffect(.degrees(isRotated ? 180 : 0))
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.bouncy, value: isFlipped || isRotated)
        
        if card.isFlippable {
          Button {
            isFlipped.toggle()
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
        
        if card.isRotatable {
          Button {
            isRotated.toggle()
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
      
      if shouldShowPrice {
        PillText(
          "$\(card.getPrices().usd ?? card.getPrices().usdFoil ?? "0.00")"
        )
        .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
        .font(.caption)
        .fontWeight(.medium)
        .monospaced()
      }
    }
  }
  
  public init?(
    card: any MagicCard,
    layoutConfiguration: LayoutConfiguration,
    shouldShowPrice: Bool = true
  ) {
    guard let image = card.getImageURL() else {
      return nil
    }
    
    self.displayingFace = card.getCardFace(for: .front)
    self.card = card
    self.layoutConfiguration = layoutConfiguration
    displayingImageURL = image
    self.shouldShowPrice = shouldShowPrice
  }
}
