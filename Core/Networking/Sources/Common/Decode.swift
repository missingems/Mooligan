import Foundation

@propertyWrapper
struct Decode<T: Decodable> {
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
      self.value = try Decode.loadJSON(filename: filename)
    } catch {
      fatalError(error.localizedDescription)
    }
  }
  
  private static func loadJSON(filename: String) throws -> T {
    guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
      throw Error.fileNotFound
    }
    
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
  }
}
