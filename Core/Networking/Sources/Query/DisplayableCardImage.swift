import Foundation
import ScryfallKit

public enum DisplayableCardImage: Equatable {
  case transformable(
    direction: MagicCardFaceDirection,
    frontImageURL: URL,
    backImageURL: URL,
    callToActionIconName: String,
    id: UUID
  )
  
  case flippable(
    direction: MagicCardFaceDirection,
    displayingImageURL: URL,
    callToActionIconName: String,
    id: UUID
  )
  
  case single(displayingImageURL: URL, id: UUID)
  
  public var faceDirection: MagicCardFaceDirection {
    switch self {
    case let .transformable(direction, _, _, _, _):
      return direction
      
    case let .flippable(direction, _, _, _):
      return direction
      
    case .single:
      return .front
    }
  }
  
  public var id: UUID {
    switch self {
    case let .transformable(_, _, _, _, id):
      return id
      
    case let .flippable(_, _, _, id):
      return id
      
    case let .single(_ ,id):
      return id
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
        callToActionIconName: callToActionIconName,
        id: card.id
      )
    } else if
      card.isFlippable,
      let imageURL = card.getImageURL(type: .normal),
      let callToActionIconName = card.layout.callToActionIconName {
      self = .flippable(
        direction: .front,
        displayingImageURL: imageURL,
        callToActionIconName: callToActionIconName,
        id: card.id
      )
    } else if let imageURL = card.getImageURL(type: .normal) {
      self = .single(displayingImageURL: imageURL, id: card.id)
    } else {
      fatalError("Impossible state: ImageURL cannot be nil.")
    }
  }
}
