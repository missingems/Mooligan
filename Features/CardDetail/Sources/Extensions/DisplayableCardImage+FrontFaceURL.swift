import Foundation
import Networking

extension DisplayableCardImage {
  var showingFaceURL: URL {
    switch self {
    case let .transformable(direction, frontImageURL, backImageURL, _, _):
      direction == .front ? frontImageURL : backImageURL

    case let .flippable(_, displayingImageURL, _, _):
      displayingImageURL

    case let .single(displayingImageURL, _):
      displayingImageURL
    }
  }

  var frontFaceURL: URL {
    switch self {
    case let .transformable(_, frontImageURL, _, _, _):
      frontImageURL

    case let .flippable(_, displayingImageURL, _, _):
      displayingImageURL

    case let .single(displayingImageURL, _):
      displayingImageURL
    }
  }
}
