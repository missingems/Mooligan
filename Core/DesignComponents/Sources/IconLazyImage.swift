import SwiftUI

public struct IconLazyImage: View {
  private let url: URL?
  private let tintColor: Color
  
  public init(_ url: URL?, tintColor: Color = DesignComponentsAsset.accentColor.swiftUIColor) {
    self.url = url
    self.tintColor = tintColor
  }
  
  public var body: some View {
    if let url {
      Text("")
//      WebImage(url: URL.init(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/625px-Apple_logo_black.svg.png")!)
//        .resizable()
//        .renderingMode(.template)
//        .aspectRatio(contentMode: .fit)
//        .foregroundColor(tintColor)
    }
  }
}
