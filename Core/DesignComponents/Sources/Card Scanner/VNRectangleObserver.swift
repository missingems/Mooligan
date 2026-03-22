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
    request.maximumObservations = 1
    request.minimumConfidence = 0.8
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
