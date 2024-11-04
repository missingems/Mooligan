import Networking
import SwiftUI

public struct CardView: View {
  public enum LayoutConfiguration: Sendable, Equatable {
    case fixedWidth(CGFloat)
    case fixedSize(CGSize)
    case flexible
  }
  
  let card: any MagicCard
  let displayingImageURL: URL
  let layoutConfiguration: LayoutConfiguration
  let shouldShowPrice: Bool
  
  public var body: some View {
    VStack(spacing: 5) {
      switch layoutConfiguration {
      case let .fixedSize(size):
        AmbientWebImage(
          url: displayingImageURL,
          cornerRadius: 5 / 100 * size.width,
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
    
    self.card = card
    self.layoutConfiguration = layoutConfiguration
    displayingImageURL = image
    self.shouldShowPrice = shouldShowPrice
  }
}
