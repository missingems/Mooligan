public struct OCRCardScannedResult: Equatable, Sendable {
  public let title: String
  public let set: String?
  public let code: String?
  
  public init(title: String, set: String?, code: String?) {
    self.title = title
    self.set = set
    self.code = code
  }
}
