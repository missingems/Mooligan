import Foundation
import Nuke

public struct Main {
  public init() {
    ImageDecoderRegistry.shared.register { context in
      func isSVG(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
          return false
        }
        
        let pathExtension = url.pathExtension
        return pathExtension.lowercased() == "svg"
      }
      
      
      let url = context.request.url?.absoluteString
      
      if let url, isSVG(urlString: url) {
        return ImageDecoders.Empty()
      } else {
        return nil
      }
    }
  }
  
  public func setup() {}
}
