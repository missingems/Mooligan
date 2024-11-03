import SDWebImage
import SDWebImageSVGNativeCoder

public struct Main {
  public init() {}
  
  public func setup() {
    let coder = SDImageSVGNativeCoder.shared
    SDImageCodersManager.shared.addCoder(coder)
    SDImageCache.shared.config.maxMemoryCost = 10000000 * 20 // 200mb
    SDImageCache.shared.config.maxDiskSize = 100000000 * 20 // 200mb
  }
}
