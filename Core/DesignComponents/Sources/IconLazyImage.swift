import Nuke
import SwiftUI

public final class SVGDataLoader: Nuke.DataLoading {
  public func loadData(
    with request: URLRequest,
    didReceiveData: @escaping (Data, URLResponse) -> Void,
    completion: @escaping ((any Error)?) -> Void
  ) -> any Nuke.Cancellable {
  }
}

public struct IconLazyImage: View {
  private let url: URL?
  private let tintColor: Color
  
  public init(_ url: URL?, tintColor: Color = DesignComponentsAsset.accentColor.swiftUIColor) {
    self.url = url
    self.tintColor = tintColor
  }
  
  public var body: some View {
    EmptyView()
//    WebImage(url: url) { image in
//      image.transition(.fade(duration: 0.25))
//    } placeholder: {
//      Circle().foregroundColor(Color.black.opacity(0.15)).shimmering()
//    }
//    .resizable()
//    .renderingMode(.template)
//    .aspectRatio(contentMode: .fit)
//    .foregroundColor(tintColor)
  }
}
