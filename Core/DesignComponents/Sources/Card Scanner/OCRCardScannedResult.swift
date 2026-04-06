import Vision
import UIKit

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
}
