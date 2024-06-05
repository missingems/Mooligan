import SDWebImageSVGNativeCoder

public struct Main {
  public init() {}
  
  public func setup() {
    let SVGCoder = SDImageSVGNativeCoder.shared
    SDImageCodersManager.shared.addCoder(SVGCoder)
    
    SDImageCache.shared.config.maxMemoryCost = 10000000 * 20 // 200mb
    SDImageCache.shared.config.maxDiskSize = 100000000 * 20 // 200mb
  }
}
