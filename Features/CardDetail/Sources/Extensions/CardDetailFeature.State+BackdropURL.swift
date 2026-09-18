import Foundation
import Networking

extension CardDetailFeature.State {
  /// The art a page blurs behind itself: the face on show, so a card turned over has its back there.
  var backdropURL: URL? {
    content.card.getImageURL(type: .normal, getSecondFace: displayableCardImage?.faceDirection == .back)
  }
}
