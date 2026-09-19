import CoreImage
import Foundation

/// Builds the frame the scanner's camera would deliver for a card in an
/// environment, and where the card's corners really are in it.
struct FrameComposer {
  let context = CIContext()

  func compose(
    _ card: CGImage,
    in environment: SimulatedEnvironment,
    seed: String
  ) -> (frame: CGImage, corners: VNRectangleObserver.Corners) {
    var random = SplitMix(seed: seed)
    // 1080p held upright, as the scanner's camera delivers it.
    let bounds = CGRect(x: 0, y: 0, width: 1080, height: 1920)

    var face = CIImage(cgImage: card)
    // Scryfall's images show the card on white; cut its rounded corners out.
    let shape = CIFilter(name: "CIRoundedRectangleGenerator", parameters: [
      "inputExtent": CIVector(cgRect: face.extent),
      "inputRadius": face.extent.width * 0.047,
      "inputColor": CIColor.white,
    ])!.outputImage!
    face = face.applyingFilter("CIBlendWithAlphaMask", parameters: [
      kCIInputBackgroundImageKey: CIImage.empty(),
      kCIInputMaskImageKey: shape,
    ])
    if environment == .foil {
      face = foiled(face)
    }

    // Where the card lands: near the centre and a little turned; smaller when
    // held far away, and with its far edge narrower when tilted.
    let width = bounds.width * (environment == .far ? 0.46 : 0.72)
    let height = width * face.extent.height / face.extent.width
    let center = CGPoint(
      x: bounds.midX + CGFloat.random(in: -0.03...0.03, using: &random) * bounds.width,
      y: bounds.midY + CGFloat.random(in: -0.03...0.03, using: &random) * bounds.height
    )
    let angle = CGFloat.random(in: -4...4, using: &random) * .pi / 180
    let taper = environment == .angled ? 0.12 * width : 0
    let drop = environment == .angled ? 0.06 * height : 0
    func placed(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(
        x: center.x + x * cos(angle) - y * sin(angle),
        y: center.y + x * sin(angle) + y * cos(angle)
      )
    }
    let topLeft = placed(-width / 2 + taper, height / 2 - drop)
    let topRight = placed(width / 2 - taper, height / 2 - drop)
    let bottomLeft = placed(-width / 2, -height / 2)
    let bottomRight = placed(width / 2, -height / 2)
    let cardInFrame = face.applyingFilter("CIPerspectiveTransform", parameters: [
      "inputTopLeft": CIVector(cgPoint: topLeft),
      "inputTopRight": CIVector(cgPoint: topRight),
      "inputBottomLeft": CIVector(cgPoint: bottomLeft),
      "inputBottomRight": CIVector(cgPoint: bottomRight),
    ])

    var frame = cardInFrame.composited(over: background(for: environment, in: bounds))
    frame = lit(frame, card: cardInFrame, in: environment, random: &random)
    let image = context.createCGImage(
      frame.cropped(to: bounds),
      from: bounds,
      format: .RGBA8,
      colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
    )!

    func normalised(_ point: CGPoint) -> CGPoint {
      CGPoint(x: point.x / bounds.width, y: point.y / bounds.height)
    }
    return (image, VNRectangleObserver.Corners(
      topLeft: normalised(topLeft),
      topRight: normalised(topRight),
      bottomLeft: normalised(bottomLeft),
      bottomRight: normalised(bottomRight)
    ))
  }

  /// Wood, a dark playmat or a white table, with a little grain.
  private func background(for environment: SimulatedEnvironment, in bounds: CGRect) -> CIImage {
    let (color, streak): (CIColor, CGFloat) = switch environment {
    case .playmat: (CIColor(red: 0.07, green: 0.08, blue: 0.11), 1)
    case .white: (CIColor(red: 0.92, green: 0.92, blue: 0.90), 1)
    // Wood grain runs along the table.
    default: (CIColor(red: 0.45, green: 0.32, blue: 0.21), 30)
    }
    return grain(strength: 0.08, streak: streak)
      .applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey: CIImage(color: color)])
      .cropped(to: bounds)
  }

  /// Grey noise centred on zero, to add to an image.
  private func grain(strength: CGFloat, streak: CGFloat) -> CIImage {
    CIFilter(name: "CIRandomGenerator")!.outputImage!
      .transformed(by: CGAffineTransform(scaleX: streak, y: 1))
      .applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: strength, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: strength, y: 0, z: 0, w: 0),
        "inputBVector": CIVector(x: strength, y: 0, z: 0, w: 0),
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        "inputBiasVector": CIVector(x: -strength / 2, y: -strength / 2, z: -strength / 2, w: 1),
      ])
  }

  /// Light, reflections and camera effects over the whole frame.
  private func lit(
    _ frame: CIImage,
    card: CIImage,
    in environment: SimulatedEnvironment,
    random: inout SplitMix
  ) -> CIImage {
    let cardBounds = card.extent
    func reflection(strength: CGFloat) -> CIImage {
      let center = CIVector(
        x: cardBounds.minX + CGFloat.random(in: 0.25...0.75, using: &random) * cardBounds.width,
        y: cardBounds.minY + CGFloat.random(in: 0.25...0.75, using: &random) * cardBounds.height
      )
      return CIFilter(name: "CIRadialGradient", parameters: [
        "inputCenter": center,
        "inputRadius0": 0,
        "inputRadius1": cardBounds.width * 0.35,
        "inputColor0": CIColor(red: 1, green: 1, blue: 1, alpha: strength),
        "inputColor1": CIColor(red: 1, green: 1, blue: 1, alpha: 0),
      ])!.outputImage!
    }

    switch environment {
    case .warm, .cool:
      // Moving the target neutral down warms the picture; up cools it.
      return frame.applyingFilter("CITemperatureAndTint", parameters: [
        "inputNeutral": CIVector(x: 6500, y: 0),
        "inputTargetNeutral": CIVector(x: environment == .warm ? 4000 : 10000, y: 0),
      ])
    case .dim:
      return grain(strength: 0.06, streak: 1)
        .applyingFilter("CIAdditionCompositing", parameters: [
          kCIInputBackgroundImageKey: frame.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: -1.6]),
        ])
    case .glare:
      return reflection(strength: 0.6).composited(over: frame)
    case .sleeve:
      let haze = CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: 0.1))
        .cropped(to: cardBounds)
        .applyingFilter("CIBlendWithAlphaMask", parameters: [
          kCIInputBackgroundImageKey: CIImage.empty(),
          kCIInputMaskImageKey: card,
        ])
      return reflection(strength: 0.35).composited(over: haze.composited(over: frame))
    case .blur:
      return frame.clampedToExtent().applyingGaussianBlur(sigma: 3)
    case .motion:
      return frame.clampedToExtent().applyingFilter("CIMotionBlur", parameters: [
        kCIInputRadiusKey: 6,
        kCIInputAngleKey: CGFloat.random(in: 0...(.pi), using: &random),
      ])
    case .clean, .foil, .angled, .far, .playmat, .white:
      return frame
    }
  }

  /// A rainbow sheen in bands across the card, at half strength.
  private func foiled(_ face: CIImage) -> CIImage {
    let bands = CIFilter(name: "CIStripesGenerator", parameters: [
      "inputColor0": CIColor(red: 1, green: 0.3, blue: 0.8),
      "inputColor1": CIColor(red: 0.2, green: 1, blue: 0.9),
      "inputWidth": 60,
      "inputSharpness": 0,
    ])!.outputImage!
      .transformed(by: CGAffineTransform(rotationAngle: .pi / 5))
      .cropped(to: face.extent)
    let sheen = bands
      .applyingFilter("CISoftLightBlendMode", parameters: [kCIInputBackgroundImageKey: face])
      .applyingFilter("CIColorMatrix", parameters: ["inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.5)])
    return sheen.composited(over: face).applyingFilter("CIBlendWithAlphaMask", parameters: [
      kCIInputBackgroundImageKey: CIImage.empty(),
      kCIInputMaskImageKey: face,
    ])
  }
}
