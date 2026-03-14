import Foundation
import CoreImage
import Vision

struct VNRectangleObserver {
  struct Corners {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
  }
  
  let imageBuffer: CVImageBuffer
  let request = VNDetectRectanglesRequest()
  let handler: VNImageRequestHandler
  
  init?(imageBuffer: CVImageBuffer?) {
    guard let imageBuffer else {
      return nil
    }
    self.imageBuffer = imageBuffer
    
    request.maximumObservations = 1
    request.minimumConfidence = 0.8
    
    handler = VNImageRequestHandler(
      cvPixelBuffer: imageBuffer,
      orientation: .right
    )
  }
  
  @MainActor func proccess(
    onUpdate: @escaping @Sendable @MainActor (Corners) -> Void
  ) {
    try? handler.perform([request])
    
    request.results?.forEach { [onUpdate] observation in
      onUpdate(
        Corners(
          topLeft: observation.topLeft,
          topRight: observation.topRight,
          bottomLeft: observation.bottomLeft,
          bottomRight: observation.bottomRight
        )
      )
    }
  }
}
