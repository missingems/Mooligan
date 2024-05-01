import SDWebImageSwiftUI
import SwiftUI

public struct IconLazyImage: View {
  private let url: URL?
  private let tintColor: Color
  
  public init(_ url: URL?, tintColor: Color = .accentColor) {
    self.url = url
    self.tintColor = tintColor
  }
  
  public var body: some View {
    if let url {
      WebImage(url: url)
        .resizable()
        .renderingMode(.template)
        .aspectRatio(contentMode: .fit)
        .foregroundColor(tintColor)
    }
  }
}
