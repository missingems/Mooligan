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
    switch layoutConfiguration {
    case let .fixedSize(size):
      AmbientWebImage(
        url: displayingImageURL,
        cornerRadius: 5/100 * size.width
      )
      .frame(
        width: size.width,
        height: size.height,
        alignment: .center
      )
      
    case let .fixedWidth(width):
      AmbientWebImage(
        url: displayingImageURL,
        cornerRadius: 5/100 * width
      )
      .frame(
        width: width,
        height: width * MagicCardImageRatio.heightToWidth.rawValue,
        alignment: .center
      )
      
    case .flexible:
      AmbientWebImage(url: displayingImageURL)
    }
    
    PillText(
      "$\(card.getPrices().usdFoil ?? card.getPrices().usd ?? "0.00")"
    )
    .font(.caption)
    .monospaced()
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
