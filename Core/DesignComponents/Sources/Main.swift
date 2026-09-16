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
    
    let pipeline = ImagePipeline {
      let dataLoader: DataLoader = {
        let config = URLSessionConfiguration.default
        config.urlCache = nil
        return DataLoader(configuration: config)
      }()
      
      $0.dataLoader = dataLoader
      // Without a data cache the policy below did nothing, and every card image and set icon came
      // back over the network as soon as it left the in-memory cache (which is wiped under memory
      // pressure and trimmed on backgrounding). The original data is kept on disk instead, so a
      // purge costs a decode, not a download.
      $0.dataCache = try? DataCache(name: "com.missingems.mooligan.images")
      $0.dataCachePolicy = .storeOriginalData
    }

    // Decoded bitmaps only need to outlive a screen, not a session: with the disk cache above a
    // miss is cheap, whereas Nuke's default (15% of RAM, up to 768 MB) fills the device's memory
    // with card images and invites the memory-pressure purge that empties every cache at once.
    ImageCache.shared.costLimit = 200 * 1024 * 1024
    
    ImagePipeline.shared = pipeline
  }
  
  public func setup() {}
}
