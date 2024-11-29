import Foundation
import Nuke

public struct Main {
  public init() {
    ImageDecoderRegistry.shared.register { context in
      func isSVG(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
          return false
        }
        
        // Extract the path extension
        let pathExtension = url.pathExtension
        
        // Check if the extension matches "svg"
        return pathExtension.lowercased() == "svg"
      }
      
      
      let url = context.request.url?.absoluteString
      
      if let url, isSVG(urlString: url) {
        print("is svg")
        return ImageDecoders.Empty()
      } else {
        print("is not svg")
        return nil
      }
    }
  }
  
  public func setup() {}
}
