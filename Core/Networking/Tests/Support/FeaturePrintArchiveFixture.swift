import Foundation

/// A real archived `VNFeaturePrintObservation` (revision 2), shrunk to four
/// elements, that tests turn into database entries with vectors of their own.
enum FeaturePrintArchiveFixture {
  private static let template = Data(base64Encoded: """
YnBsaXN0MDDUAQIDBAV6fX5YJG9iamVjdHNUJHRvcFkkYXJjaGl2ZXJYJHZlcnNpb26vEBkGBxkfJiotNzg5RUZHSEkTSk1ZWl5r
bHF0VSRudWxs2QgJCgsMDQ4PEBESExQVExYXGFYkY2xhc3NZdGltZVJhbmdlXVZOT2JzZXJ2YXRpb25aY29uZmlkZW5jZVR1dWlk
XxASVk5TY2VuZU9ic2VydmF0aW9uV3JlcXVlc3RbZGVzY3JpcHRvcnNUYWxnb4AYgAYQACI/gAAAgASAAoATgBLTGggbHB0eU3Jl
dlRjb2RlEAKAAxJHSUZQ0iAhIiNaJGNsYXNzbmFtZVgkY2xhc3Nlc18QElZOUmVxdWVzdFNwZWNpZmllcqIkJV8QElZOUmVxdWVz
dFNwZWNpZmllclhOU09iamVjdNInCCgpXE5TLnV1aWRieXRlc08QEDHpmvaPHkZ/in/TVtf6vnKABdIgISssVk5TVVVJRKIrJdMu
LwgwMzZXTlMua2V5c1pOUy5vYmplY3RzojEygAeACKI0NYAJgBGAEFVzdGFydFhkdXJhdGlvbtMuLwg6PzakOzw9PoAKgAuADIAN
pEBBQEGADoAPgA6AD4AQVWZsYWdzVXZhbHVlWXRpbWVzY2FsZVVlcG9jaBAB0iAhS0xcTlNEaWN0aW9uYXJ5oksl0y4vCE5TNqQ7
PD0+gAqAC4AMgA2kQEFAQYAOgA+ADoAPgBBTMS4w0i8IW12hXIAUgBfYCF9gYQ5iY2RlGGdJFklpal8QEGFsZ29yaXRobVZlcnNp
b25eZGVzY3JpcHRvckRhdGFcZWxlbWVudHNUeXBlV3ZlcnNpb25fEBRkZXNjcmlwdG9yQnl0ZUxlbmd0aFxlbGVtZW50Q291bnSA
FoASgBWAAhAQEARPEBAAAAA/AACAPgAAAAAAAIA/0iAhbW5cVk5TY2VuZXByaW50o29wJVxWTlNjZW5lcHJpbnRfEBlWTkVzcHJl
c3NvTW9kZWxJbWFnZXByaW500iAhcnNXTlNBcnJheaJyJdIgIXV2XxASVk5TY2VuZU9ic2VydmF0aW9upHd4eSVfEBJWTlNjZW5l
T2JzZXJ2YXRpb25fEBlWTkZlYXR1cmVQcmludE9ic2VydmF0aW9uXVZOT2JzZXJ2YXRpb27Re3xUcm9vdIABXxAPTlNLZXllZEFy
Y2hpdmVyEgABhqAACAARABoAHwApADIATgBUAGcAbgB4AIYAkQCWAKsAswC/AMQAxgDIAMoAzwDRANMA1QDXAN4A4gDnAOkA6wDw
APUBAAEJAR4BIQE2AT8BRAFRAWQBZgFrAXIBdQF8AYQBjwGSAZQBlgGZAZsBnQGfAaUBrgG1AboBvAG+AcABwgHHAckBywHNAc8B
0QHXAd0B5wHtAe8B9AIBAgQCCwIQAhICFAIWAhgCHQIfAiECIwIlAicCKwIwAjICNAI2AkcCWgJpAnYCfgKVAqICpAKmAqgCqgKs
Aq4CwQLGAtMC1wLkAwADBQMNAxADFQMqAy8DRANgA24DcQN2A3gDigAAAAAAAAIBAAAAAAAAAH8AAAAAAAAAAAAAAAAAAAOP
""", options: .ignoreUnknownCharacters)!

  /// An archive the app's decoder reads back as `vector`.
  static func archive(_ vector: [Float]) throws -> Data {
    guard var plist = try PropertyListSerialization.propertyList(from: template, options: [], format: nil) as? [String: Any],
          var objects = plist["$objects"] as? [Any],
          let descriptorPosition = objects.firstIndex(where: { ($0 as? [String: Any])?["descriptorByteLength"] != nil }),
          var descriptor = objects[descriptorPosition] as? [String: Any],
          let dataPosition = objects.firstIndex(where: { ($0 as? Data)?.count == 16 })
    else { throw CocoaError(.propertyListReadCorrupt) }

    objects[dataPosition] = vector.withUnsafeBytes { Data($0) }
    descriptor["descriptorByteLength"] = vector.count * 4
    descriptor["elementCount"] = vector.count
    objects[descriptorPosition] = descriptor
    plist["$objects"] = objects
    return try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
  }
}
