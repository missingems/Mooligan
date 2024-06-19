import Foundation

class Resource {}

@propertyWrapper
struct Decode<T: Decodable & Sendable>: Sendable {
  enum Error: Swift.Error {
    case fileNotFound
  }
  
  private var value: T
  
  var wrappedValue: T {
    get { value }
    set { value = newValue }
  }
  
  init(_ filename: String) {
    do {
      value = try Decode.loadJSON(filename: filename)
    } catch {
      fatalError(error.localizedDescription)
    }
  }
  
  private static func loadJSON(filename: String) throws -> T {
    guard let url = Bundle(for: Resource.self).url(forResource: filename, withExtension: nil) else {
      throw Error.fileNotFound
    }
    
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(T.self, from: data)
  }
}
