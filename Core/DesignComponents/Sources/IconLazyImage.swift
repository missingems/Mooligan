import Nuke
import SVGView
import SwiftUI
import UIKit

public struct IconLazyImage: View {
  private let url: URL?
  private let tintColor: Color

  // The icon as a template bitmap, drawn from the SVG off the main thread at the size it is shown.
  // Rendering the SVG as SwiftUI views put a `compositingGroup` per SVG group inside a mask, which
  // SwiftUI can only draw with Metal on the main thread: every icon was a synchronous GPU draw, and
  // the animated loading shimmer repeated that draw on every frame until the icon arrived.
  @State private var icon: UIImage?
  @State private var pixelSize: CGSize = .zero

  @Environment(\.displayScale) private var displayScale

  public init(_ url: URL?, tintColor: Color = DesignComponentsAsset.accentColor.swiftUIColor) {
    self.url = url
    self.tintColor = tintColor
    _icon = State(initialValue: url.flatMap(SVGIconCache.latestImage(for:)))
  }

  public var body: some View {
    Color.clear
      .overlay {
        if let icon {
          Image(uiImage: icon)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(tintColor)
        } else {
          // Deliberately static: an animated placeholder redraws on every frame the icon is loading.
          EllipticalGradient(
            colors: [Color.primary.opacity(0.35), Color.primary.opacity(0.0)],
            center: .center,
            startRadiusFraction: 0.0,
            endRadiusFraction: 0.5
          )
        }
      }
      .onGeometryChange(for: CGSize.self) { [displayScale] geometry in
        CGSize(
          width: (geometry.size.width * displayScale).rounded(),
          height: (geometry.size.height * displayScale).rounded()
        )
      } action: { size in
        pixelSize = size
      }
      .task(id: SVGIconRequest(url: url, pixelSize: pixelSize), priority: .utility) {
        await load()
      }
  }

  private func load() async {
    guard let url, pixelSize.width > 0.0, pixelSize.height > 0.0 else { return }

    let request = SVGIconRequest(url: url, pixelSize: pixelSize)
    if let cached = SVGIconCache.image(for: request) {
      if icon !== cached { icon = cached }
      return
    }

    let started = ContinuousClock.now
    guard let response = try? await ImagePipeline.shared.imageTask(with: url).response,
          let data = response.container.data,
          let rendered = await SVGIconRenderer.render(data, pixelSize: pixelSize, scale: displayScale)
    else { return }

    SVGIconCache.insert(rendered, for: request)
    guard Task.isCancelled == false else { return }

    // Only an icon slow enough to have shown the placeholder fades in; a cached one just appears.
    if icon == nil, ContinuousClock.now - started > .milliseconds(150) {
      withAnimation(.smooth) { icon = rendered }
    } else {
      icon = rendered
    }
  }
}

private struct SVGIconRequest: Equatable {
  let url: URL?
  let pixelSize: CGSize
}

@MainActor
private enum SVGIconCache {
  private static let images: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.totalCostLimit = 32 * 1024 * 1024
    return cache
  }()

  // The last size drawn for each icon, shown straight away when the same icon appears at another
  // size while that size is drawn.
  private static let latest = NSCache<NSURL, UIImage>()

  static func image(for request: SVGIconRequest) -> UIImage? {
    guard let url = request.url else { return nil }
    return images.object(forKey: key(url, request.pixelSize))
  }

  static func latestImage(for url: URL) -> UIImage? {
    latest.object(forKey: url as NSURL)
  }

  static func insert(_ image: UIImage, for request: SVGIconRequest) {
    guard let url = request.url else { return }
    let cost = Int(request.pixelSize.width * request.pixelSize.height) * 4
    images.setObject(image, forKey: key(url, request.pixelSize), cost: cost)
    latest.setObject(image, forKey: url as NSURL)
  }

  private static func key(_ url: URL, _ size: CGSize) -> NSString {
    "\(url.absoluteString)@\(Int(size.width))x\(Int(size.height))" as NSString
  }
}

/// Draws an SVG's coverage into a bitmap with Core Graphics, placed the way `SVGView` places it (the
/// view box scaled to fit and centred). Only coverage matters, because the icon is tinted as a
/// template, so fills and strokes are drawn in black at their own opacity, and gradients as solid.
private enum SVGIconRenderer {
  @concurrent static func render(_ data: Data, pixelSize: CGSize, scale: CGFloat) async -> UIImage? {
    guard let root = SVGParser.parse(data: data) else { return nil }

    let width = Int(pixelSize.width)
    let height = Int(pixelSize.height)
    let pointSize = CGSize(width: pixelSize.width / scale, height: pixelSize.height / scale)
    let viewBox = viewBox(of: root, pointSize: pointSize)
    guard width > 0, height > 0, viewBox.width > 0.0, viewBox.height > 0.0,
          let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          )
    else { return nil }

    let fit = min(pixelSize.width / viewBox.width, pixelSize.height / viewBox.height)
    // SVG's y axis points down; the bitmap's points up.
    context.translateBy(x: 0.0, y: pixelSize.height)
    context.scaleBy(x: 1.0, y: -1.0)
    context.translateBy(
      x: (pixelSize.width - viewBox.width * fit) / 2.0,
      y: (pixelSize.height - viewBox.height * fit) / 2.0
    )
    context.scaleBy(x: fit, y: fit)
    context.translateBy(x: -viewBox.minX, y: -viewBox.minY)
    draw(root, in: context)

    guard let image = context.makeImage() else { return nil }
    return UIImage(cgImage: image, scale: scale, orientation: .up)
  }

  private static func viewBox(of root: SVGNode, pointSize: CGSize) -> CGRect {
    guard let viewport = root as? SVGViewport else { return CGRect(origin: .zero, size: pointSize) }
    if let viewBox = viewport.viewBox { return viewBox }
    return CGRect(
      x: 0.0,
      y: 0.0,
      width: viewport.width.toPixels(total: pointSize.width),
      height: viewport.height.toPixels(total: pointSize.height)
    )
  }

  private static func draw(_ node: SVGNode, in context: CGContext) {
    guard node.opacity > 0.0 else { return }

    context.saveGState()
    defer { context.restoreGState() }
    context.concatenate(node.transform)

    // `SVGView` itself only honours user-space clips.
    if let clip = node.clip as? SVGUserSpaceNode, clip.userSpace == .userSpaceOnUse {
      let path = CGMutablePath()
      appendOutline(of: clip.node, to: path, transform: .identity)
      context.addPath(path)
      context.clip()
    }

    // Group opacity applies to the composited group, as `SVGView`'s `compositingGroup` did.
    let isTranslucent = node.opacity < 1.0
    if isTranslucent {
      context.setAlpha(node.opacity)
      context.beginTransparencyLayer(auxiliaryInfo: nil)
    }

    switch node {
    case let group as SVGGroup:
      for child in group.contents {
        draw(child, in: context)
      }
    case let userSpace as SVGUserSpaceNode:
      draw(userSpace.node, in: context)
    case let shape as SVGShape:
      paint(shape, in: context)
    default:
      // Text and embedded images do not appear in set icons.
      break
    }

    if isTranslucent {
      context.endTransparencyLayer()
    }
  }

  private static func paint(_ shape: SVGShape, in context: CGContext) {
    guard let outline = outline(of: shape) else { return }

    if let alpha = alpha(of: shape.fill), alpha > 0.0 {
      context.addPath(outline)
      context.setFillColor(gray: 0.0, alpha: alpha)
      context.fillPath(using: (shape as? SVGPath)?.fillRule == .evenOdd ? .evenOdd : .winding)
    }

    if let stroke = shape.stroke, stroke.width > 0.0, let alpha = alpha(of: stroke.fill), alpha > 0.0 {
      context.addPath(outline)
      context.setLineWidth(stroke.width)
      context.setLineCap(stroke.cap)
      context.setLineJoin(stroke.join)
      context.setMiterLimit(stroke.miterLimit)
      if stroke.dashes.isEmpty == false {
        context.setLineDash(phase: stroke.offset, lengths: stroke.dashes)
      }
      context.setStrokeColor(gray: 0.0, alpha: alpha)
      context.strokePath()
    }
  }

  private static func alpha(of paint: SVGPaint?) -> CGFloat? {
    switch paint {
    case nil: nil
    case let color as SVGColor: CGFloat(color.opacity)
    default: 1.0
    }
  }

  private static func appendOutline(of node: SVGNode, to path: CGMutablePath, transform: CGAffineTransform) {
    let transform = node.transform.concatenating(transform)
    switch node {
    case let group as SVGGroup:
      for child in group.contents {
        appendOutline(of: child, to: path, transform: transform)
      }
    case let userSpace as SVGUserSpaceNode:
      appendOutline(of: userSpace.node, to: path, transform: transform)
    case let shape as SVGShape:
      if let outline = outline(of: shape) {
        path.addPath(outline, transform: transform)
      }
    default:
      break
    }
  }

  private static func outline(of shape: SVGShape) -> CGPath? {
    switch shape {
    case let path as SVGPath:
      return path.toBezierPath().cgPath
    case let rect as SVGRect:
      let frame = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
      guard frame.width > 0.0, frame.height > 0.0 else { return nil }
      return CGPath(
        roundedRect: frame,
        cornerWidth: min(max(rect.rx, 0.0), frame.width / 2.0),
        cornerHeight: min(max(rect.ry, 0.0), frame.height / 2.0),
        transform: nil
      )
    case let circle as SVGCircle:
      let diameter = circle.r * 2.0
      return CGPath(ellipseIn: CGRect(x: circle.cx - circle.r, y: circle.cy - circle.r, width: diameter, height: diameter), transform: nil)
    case let ellipse as SVGEllipse:
      return CGPath(
        ellipseIn: CGRect(x: ellipse.cx - ellipse.rx, y: ellipse.cy - ellipse.ry, width: ellipse.rx * 2.0, height: ellipse.ry * 2.0),
        transform: nil
      )
    case let polygon as SVGPolygon:
      return lines(through: polygon.points, closed: true)
    case let polyline as SVGPolyline:
      return lines(through: polyline.points, closed: false)
    case let line as SVGLine:
      return lines(through: [CGPoint(x: line.x1, y: line.y1), CGPoint(x: line.x2, y: line.y2)], closed: false)
    default:
      return nil
    }
  }

  private static func lines(through points: [CGPoint], closed: Bool) -> CGPath? {
    guard points.isEmpty == false else { return nil }
    let path = CGMutablePath()
    path.addLines(between: points)
    if closed {
      path.closeSubpath()
    }
    return path
  }
}
