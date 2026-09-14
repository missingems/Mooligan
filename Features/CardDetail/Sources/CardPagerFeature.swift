import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

@Reducer
public struct CardPagerFeature: Sendable {
  @ObservableState
  public struct State: Equatable {
    public var cards: IdentifiedArrayOf<CardDetailFeature.State>
    public var selectedId: UUID?
    @Presents public var showRulings: RulingFeature.State?
    /// The card the pager last came to rest on, whose price history is loading or loaded.
    var settledCardID: UUID?
    var rawCardDetails: [CardInfo]
    var queryType: QueryType
    
    public init(cardDetails: [CardInfo], initialSelectedCard: Card, queryType: QueryType) {
      self.rawCardDetails = cardDetails
      self.queryType = queryType
      self.selectedId = initialSelectedCard.id
      
      if let initialInfo = cardDetails.first(where: { $0.card.id == initialSelectedCard.id }) {
        self.cards = [
          CardDetailFeature.State(
            card: initialInfo.card,
            displayableCardImage: initialInfo.displayableCardImage,
            queryType: queryType
          )
        ]
      } else {
        self.cards = []
      }
    }
  }
  
  public enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case cards(IdentifiedActionOf<CardDetailFeature>)
    case currentCardSettled(id: UUID?)
    case showRulings(PresentationAction<RulingFeature.Action>)
    case viewAppeared
    case setRemainingCards(IdentifiedArrayOf<CardDetailFeature.State>)
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
        
      case .viewAppeared:
        let loadInitialCard: Effect<Action> = .send(.currentCardSettled(id: state.selectedId))
        
        guard state.cards.count < state.rawCardDetails.count else { return loadInitialCard }
        
        let rawDetails = state.rawCardDetails
        let query = state.queryType
        
        return .merge(
          loadInitialCard,
          .run(priority: .background) { send in
            let mapped = rawDetails.map { info in
              CardDetailFeature.State(
                card: info.card,
                displayableCardImage: info.displayableCardImage,
                queryType: query
              )
            }
            
            await send(.setRemainingCards(IdentifiedArray(uniqueElements: mapped)))
          }
        )
        
      case let .currentCardSettled(id):
        guard
          let id,
          let card = state.cards[id: id]?.content.card
        else {
          return .none
        }
        
        let appeared: Effect<Action> = .send(
          .cards(
            .element(
              id: id,
              action: .viewAppeared(initialAction: .fetchAdditionalInformation(card: card))
            )
          )
        )

        // Price history follows the settled card: its debounced load starts here and the card
        // left behind has its load cancelled, so swiping through cards fetches nothing for the
        // ones passed. This lives in the reducer rather than a view `.task`, because the lazy
        // stack gives off-screen neighbour pages `onAppear` too, and driving it from view state
        // re-rendered every page on each swipe.
        let previous = state.settledCardID
        guard previous != id else { return appeared }
        state.settledCardID = id

        let left: Effect<Action> = if let previous, state.cards[id: previous] != nil {
          .send(.cards(.element(id: previous, action: .priceHistoryDisappeared)))
        } else {
          .none
        }
        return .merge(left, appeared, .send(.cards(.element(id: id, action: .priceHistoryAppeared))))
        
      case var .setRemainingCards(fullArray):
        for existingCard in state.cards {
          fullArray[id: existingCard.id] = existingCard
        }
        state.cards = fullArray
        return .none
        
      case let .cards(.element(id: id, action: .viewRulingsTapped)):
        guard let card = state.cards[id: id]?.content.card else {
          return .none
        }
        state.showRulings = RulingFeature.State(card: card, title: "Rulings")
        return .none
        
      case .cards:
        return .none
        
      case .showRulings:
        return .none
      }
    }
    .forEach(\.cards, action: \.cards) {
      CardDetailFeature()
    }
    .ifLet(\.$showRulings, action: \.showRulings) {
      RulingFeature()
    }
  }
  
  public init() {}
}
