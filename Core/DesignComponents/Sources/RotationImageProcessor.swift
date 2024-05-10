//
//  RotationImageProcessor.swift
//  Mooligan
//
//  Created by Jun on 13/4/24.
//

import Foundation
import Nuke
#if os(iOS)
import UIKit.UIImage
#else
import Cocoa
#endif

struct RotationImageProcessor: ImageProcessing {
  func process(_ image: Nuke.PlatformImage) -> Nuke.PlatformImage? {
    return rotate(image: image, degrees: degrees)
  }
  
  var identifier = "com.missingems.mooligan.rotationImageProcessor"
  private let degrees: CGFloat
  
  public init(degrees: CGFloat) {
    self.degrees = degrees
  }
  
  private func rotate(image: Nuke.PlatformImage, degrees: CGFloat) -> Nuke.PlatformImage? {
    guard let cgImage = image.cgImage else { return nil }
    
    let radians = degrees * CGFloat.pi / 180
    let rotatedSize = CGRect(origin: .zero, size: image.size)
      .applying(CGAffineTransform(rotationAngle: radians))
      .integral.size
    
    #if os(iOS)
    UIGraphicsBeginImageContextWithOptions(rotatedSize, false, image.scale)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    
    context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
    context.rotate(by: radians)
    
    image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
    
    let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    #else
    let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(rotatedSize.width), pixelsHigh: Int(rotatedSize.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bitmapFormat: .alphaNonpremultiplied, bytesPerRow: 0, bitsPerPixel: 0)
    
    guard let context = NSGraphicsContext(bitmapImageRep: imageRep!) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    
    context.cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
    context.cgContext.rotate(by: radians)
    
    context.cgContext.draw(cgImage, in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
    
    NSGraphicsContext.restoreGraphicsState()
    
    let rotatedImage = NSImage(size: rotatedSize)
    rotatedImage.addRepresentation(imageRep!)
    #endif
    
    return rotatedImage
  }
}
