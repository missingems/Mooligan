import Foundation
import CoreImage
import Vision

struct VNRectangleObserver: @unchecked Sendable {
  struct Corners: Sendable {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
  }
  
  private let handler: VNImageRequestHandler
  private let request: VNDetectRectanglesRequest
  
  init?(imageBuffer: CVImageBuffer?) {
    guard let imageBuffer else { return nil }
    
    handler = VNImageRequestHandler(
      cvPixelBuffer: imageBuffer,
      orientation: .right
    )
    
    request = VNDetectRectanglesRequest()
    request.minimumSize = 0.4
    request.regionOfInterest = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    request.minimumConfidence = 0.6
    request.minimumAspectRatio = VNAspectRatio(0.65)
    request.maximumAspectRatio = VNAspectRatio(0.75)
    request.maximumObservations = 1
  }
  
  func process() -> Corners? {
    try? handler.perform([request])
    
    guard let observation = request.results?.first else {
      return nil
    }
    
    return Corners(
      topLeft: observation.topLeft,
      topRight: observation.topRight,
      bottomLeft: observation.bottomLeft,
      bottomRight: observation.bottomRight
    )
  }
}
