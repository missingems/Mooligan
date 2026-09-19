import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit

public extension CardDetailFeature {
  @CasePathable enum Action: Equatable, Sendable {
    // User Actions
    case descriptionCallToActionTapped
    case didSelectVariant(card: Card, queryType: QueryType)
    case didShowVariant(index: Int)
    case viewAppeared
    case viewRulingsTapped
    case retryPriceHistoryTapped

    // Fetch Actions
    case fetchVariants(card: Card, page: Int)
    case fetchPriceHistory(card: Card)
    
    // Update/Response Actions
    case updateAdditionalInformation(AdditionalInformation)
    case updateVariants(CardDataSource, page: Int)
    case updatePriceHistory(PriceHistoryUpdate)
    case updatePullOdds(CardPullOdds?)
  }
}
