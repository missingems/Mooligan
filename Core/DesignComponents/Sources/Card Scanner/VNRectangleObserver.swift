import Foundation
import CoreImage
import Vision

/// The scanner's detect-and-crop step: finds the card in a frame and flattens it.
///
/// The camera, the simulator's stand-in frame and the Mac accuracy tool
/// (`Tools/scanner-accuracy`) all run this code, so what the tool measures is
/// what the phone does. Keep it free of UIKit for that reason.
struct VNRectangleObserver: @unchecked Sendable {
  /// Normalised to the frame, origin at the bottom left, as Vision reports them.
  struct Corners: Sendable {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
  }

  private let handler: VNImageRequestHandler
  private let request: VNDetectRectanglesRequest

  /// A camera frame, which arrives a quarter turn from upright.
  init?(imageBuffer: CVImageBuffer?) {
    guard let imageBuffer else { return nil }
    self.init(handler: VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .right))
  }

  /// An upright still frame.
  init(image: CGImage) {
    self.init(handler: VNImageRequestHandler(cgImage: image, options: [:]))
  }

  private init(handler: VNImageRequestHandler) {
    self.handler = handler

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

  /// The card inside `corners`, flattened out of `frame`: the frame they were
  /// found in, upright, in Core Image coordinates.
  static func flattenedCard(in frame: CIImage, corners: Corners, context: CIContext) -> CGImage? {
    let size = frame.extent.size
    func vector(_ point: CGPoint) -> CIVector {
      CIVector(x: point.x * size.width, y: point.y * size.height)
    }

    let card = frame.applyingFilter("CIPerspectiveCorrection", parameters: [
      "inputTopLeft": vector(corners.topLeft),
      "inputTopRight": vector(corners.topRight),
      "inputBottomLeft": vector(corners.bottomLeft),
      "inputBottomRight": vector(corners.bottomRight),
    ])
    return context.createCGImage(card, from: card.extent)
  }
}
