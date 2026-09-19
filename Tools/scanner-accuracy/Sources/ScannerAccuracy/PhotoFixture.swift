import Foundation

/// A real photo of a card, with the printing in it. Listed in Fixtures/photos.json.
struct PhotoFixture: Decodable {
  let file: String
  let faceID: String
  let description: String
}
