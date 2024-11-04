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
  
  public var body: some View {
    VStack(spacing: 5) {
      switch layoutConfiguration {
      case let .fixedSize(size):
        AmbientWebImage(
          url: displayingImageURL,
          cornerRadius: 5 / 100 * size.width
        )
        .frame(
          width: size.width,
          height: size.height,
          alignment: .center
        )
        .shadow(color: .black.opacity(0.16), radius: 13, x: 0, y: 8.0)
        
      case let .fixedWidth(width):
        AmbientWebImage(
          url: displayingImageURL,
          cornerRadius: 5 / 100 * width
        )
        .frame(
          width: width,
          height: width * MagicCardImageRatio.heightToWidth.rawValue,
          alignment: .center
        )
        .shadow(color: .black.opacity(0.16), radius: 13, x: 0, y: 8.0)
        
      case .flexible:
        AmbientWebImage(url: displayingImageURL)
          .shadow(color: .black.opacity(0.16), radius: 13, x: 0, y: 8.0)
      }
      
      PillText(
        "$\(card.getPrices().usd ?? card.getPrices().usdFoil ?? "0.00")"
      )
      .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
      .font(.caption)
      .fontWeight(.medium)
      .monospaced()
    }
  }
  
  public init?(
    card: any MagicCard,
    layoutConfiguration: LayoutConfiguration
  ) {
    guard let image = card.getImageURL() else {
      return nil
    }
    
    self.card = card
    self.layoutConfiguration = layoutConfiguration
    displayingImageURL = image
  }
}
