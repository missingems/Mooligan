import Vision
import UIKit
import SwiftUI

public struct OCRCardScannedResult: Equatable, Sendable {
  public struct SetCode: Equatable, Sendable {
    public let set: String?
    public let code: String?
    
    public init?(set: String?, code: String?) {
      guard let set, let code else { return nil }
      self.set = set
      self.code = code
    }
  }
  
  public let title: String
  public let setCode: SetCode?
  
  public init(title: String, set: String?, code: String?) {
    self.title = title
    self.setCode = SetCode(set: set, code: code)
  }
  
  static public func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.title == rhs.title
  }
}

public struct ScannedImage: Equatable, @unchecked Sendable {
  public let value: CGImage
  public let bounds: CGRect
  
  public static func == (lhs: ScannedImage, rhs: ScannedImage) -> Bool {
    return lhs.value == rhs.value
  }
}

public struct QuadCorners: Equatable, Sendable {
  public var topLeft: CGPoint
  public var topRight: CGPoint
  public var bottomRight: CGPoint
  public var bottomLeft: CGPoint
  
  public init(topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint) {
    self.topLeft = topLeft
    self.topRight = topRight
    self.bottomRight = bottomRight
    self.bottomLeft = bottomLeft
  }
  
  public func transformMatrix(for bounds: CGSize) -> CATransform3D {
    let x0 = topLeft.x, y0 = topLeft.y
    let x1 = topRight.x, y1 = topRight.y
    let x2 = bottomRight.x, y2 = bottomRight.y
    let x3 = bottomLeft.x, y3 = bottomLeft.y
    
    let dx1 = x1 - x2
    let dx2 = x3 - x2
    let dx3 = x0 - x1 + x2 - x3
    
    let dy1 = y1 - y2
    let dy2 = y3 - y2
    let dy3 = y0 - y1 + y2 - y3
    
    let det = dx1 * dy2 - dx2 * dy1
    guard det != 0 else { return CATransform3DIdentity }
    
    let a13 = (dx3 * dy2 - dx2 * dy3) / det
    let a23 = (dx1 * dy3 - dx3 * dy1) / det
    
    let a11 = x1 - x0 + a13 * x1
    let a21 = x3 - x0 + a23 * x3
    let a31 = x0
    
    let a12 = y1 - y0 + a13 * y1
    let a22 = y3 - y0 + a23 * y3
    let a32 = y0
    
    var t = CATransform3DIdentity
    t.m11 = a11
    t.m12 = a12
    t.m14 = a13
    
    t.m21 = a21
    t.m22 = a22
    t.m24 = a23
    
    t.m41 = a31
    t.m42 = a32
    
    return CATransform3DScale(t, 1.0 / bounds.width, 1.0 / bounds.height, 1.0)
  }
}

// MARK: - SwiftUI Animation
extension QuadCorners: Animatable {
  public typealias AnimatableData = AnimatablePair<
    AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData>,
    AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData>
  >
  
  public var animatableData: AnimatableData {
    get {
      AnimatablePair(
        AnimatablePair(topLeft.animatableData, topRight.animatableData),
        AnimatablePair(bottomRight.animatableData, bottomLeft.animatableData)
      )
    }
    set {
      topLeft.animatableData = newValue.first.first
      topRight.animatableData = newValue.first.second
      bottomRight.animatableData = newValue.second.first
      bottomLeft.animatableData = newValue.second.second
    }
  }
}

public struct QuadProjectionModifier: @MainActor AnimatableModifier {
  public var corners: QuadCorners
  public var logicalSize: CGSize
  
  public var animatableData: QuadCorners.AnimatableData {
    get { corners.animatableData }
    set { corners.animatableData = newValue }
  }
  
  public func body(content: Content) -> some View {
    content.projectionEffect(ProjectionTransform(corners.transformMatrix(for: logicalSize)))
  }
}

public extension View {
  func projected(to corners: QuadCorners, logicalSize: CGSize) -> some View {
    self.modifier(QuadProjectionModifier(corners: corners, logicalSize: logicalSize))
  }
}
