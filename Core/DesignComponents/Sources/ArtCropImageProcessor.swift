import Foundation
import Nuke
#if os(iOS)
import UIKit.UIImage
#else
import Cocoa
#endif

public struct ArtCropImageProcessor: ImageProcessing {
  public static let standardArtBox = CGRect(x: 0.09, y: 0.13, width: 0.82, height: 0.41)
  
  public let identifier: String
  private let artBox: CGRect
  
  public init(artBox: CGRect = ArtCropImageProcessor.standardArtBox) {
    self.artBox = artBox
    self.identifier = "com.missingems.mooligan.artCropImageProcessor:\(artBox)"
  }
  
  public func process(_ image: Nuke.PlatformImage) -> Nuke.PlatformImage? {
    guard let cgImage = image.cgImage else { return nil }
    
    let bounds = CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
    
    let cropRect = CGRect(
      x: artBox.minX * bounds.width,
      y: artBox.minY * bounds.height,
      width: artBox.width * bounds.width,
      height: artBox.height * bounds.height
    ).integral.intersection(bounds)
    
    guard
      cropRect.isEmpty == false,
      let cropped = cgImage.cropping(to: cropRect)
    else {
      return image
    }
    
    return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
  }
}
