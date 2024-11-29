import Nuke
import SVGView
import SwiftUI

public struct IconLazyImage: View {
  private let url: URL
  @State private var imageData: Data?
  private let tintColor: Color
  
  public init?(_ url: URL?, tintColor: Color = DesignComponentsAsset.accentColor.swiftUIColor) {
    guard let url else { return nil }
    self.url = url
    self.tintColor = tintColor
  }
  
  public var body: some View {
    VStack {
      if let imageData {
        SVGView(data: imageData).frame(width: 20, height: 20, alignment: .center)
//          .fill(.red)
//          .blendMode(.multiply)
//            .renderingMode(.template)
//            .aspectRatio(contentMode: .fit)
      }
    }.task {
      ImagePipeline.shared.loadImage(with: url) { result in
        self.imageData = try? result.get().container.data
      }
    }
  }
}

