public struct UnsafeSendable<Client>: @unchecked Sendable {
  public let wrappedValue: Client
  
  public init(_ value: Client) {
    self.wrappedValue = value
  }
}
