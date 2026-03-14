import Foundation
import CoreImage
import Vision

struct VNRectangleObserver: Sendable {
  struct Corners: Sendable {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
  }
  
  private final class Handler: @unchecked Sendable {
    let value: VNImageRequestHandler
    init(_ value: VNImageRequestHandler) { self.value = value }
  }
  
  private let handler: Handler
  
  init?(imageBuffer: CVImageBuffer?) {
    guard let imageBuffer else { return nil }
    handler = Handler(
      VNImageRequestHandler(
        cvPixelBuffer: imageBuffer,
        orientation: .right // This ensures Vision knows the phone is in portrait!
      )
    )
  }
  
  // Changed to a synchronous return to fix the infinite lock
  func process() -> Corners? {
    let request = VNDetectRectanglesRequest()
    request.maximumObservations = 1
    request.minimumConfidence = 0.8
    
    try? handler.value.perform([request])
    
    guard let observation = request.results?.first else { return nil }
    
    return Corners(
      topLeft: observation.topLeft,
      topRight: observation.topRight,
      bottomLeft: observation.bottomLeft,
      bottomRight: observation.bottomRight
    )
  }
}
