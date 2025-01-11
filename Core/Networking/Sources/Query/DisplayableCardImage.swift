import Foundation
import ScryfallKit

public enum DisplayableCardImage: Equatable {
  case transformable(
    direction: MagicCardFaceDirection,
    frontImageURL: URL,
    backImageURL: URL,
    callToActionIconName: String
  )
  
  case flippable(
    direction: MagicCardFaceDirection,
    displayingImageURL: URL,
    callToActionIconName: String
  )
  
  case single(displayingImageURL: URL)
  
  public var faceDirection: MagicCardFaceDirection {
    switch self {
    case let .transformable(direction, _, _, _):
      return direction
      
    case let .flippable(direction, _, _):
      return direction
      
    case .single:
      return .front
    }
  }
  
  public init(_ card: Card) {
    if card.isTransformable,
       let frontImageURL = card.getImageURL(type: .normal, getSecondFace: false),
       let backImageURL = card.getImageURL(type: .normal, getSecondFace: true),
       let callToActionIconName = card.layout.callToActionIconName {
      self = .transformable(
        direction: .front,
        frontImageURL: frontImageURL,
        backImageURL: backImageURL,
        callToActionIconName: callToActionIconName
      )
    } else if
      card.isFlippable,
      let imageURL = card.getImageURL(type: .normal),
      let callToActionIconName = card.layout.callToActionIconName {
      self = .flippable(
        direction: .front,
        displayingImageURL: imageURL,
        callToActionIconName: callToActionIconName
      )
    } else if let imageURL = card.getImageURL(type: .normal) {
      self = .single(displayingImageURL: imageURL)
    } else {
      fatalError("Impossible state: ImageURL cannot be nil.")
    }
  }
}
