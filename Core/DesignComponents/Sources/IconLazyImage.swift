import SDWebImageSwiftUI
import SwiftUI

public struct IconLazyImage: View {
  private let url: URL?
  private let tintColor: Color
  
  public init(_ url: URL?, tintColor: Color = DesignComponentsAsset.accentColor.swiftUIColor) {
    self.url = url
    self.tintColor = tintColor
  }
  
  public var body: some View {
    WebImage(url: url) { image in
      image.resizable().renderingMode(.template)
        .transition(.fade(duration: 0.25))
    } placeholder: {
      Circle().foregroundColor(Color.black.opacity(0.15)).shimmering()
    }
    .aspectRatio(contentMode: .fit)
    .foregroundColor(tintColor)
  }
}
