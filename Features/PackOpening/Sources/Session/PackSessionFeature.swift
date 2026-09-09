import ComposableArchitecture
import Foundation
import Networking

/// One pack, from sealed to summary.
@Reducer public struct PackSessionFeature: Sendable {
  @Dependency(\.continuousClock) private var clock

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .tearCompleted:
        guard state.phase == .sealed else { return .none }
        state.phase = .opening

        return .run { send in
          // Long enough for the wrapper to fly off before the fan of cards
          // takes over the screen.
          try await clock.sleep(for: .milliseconds(650))
          await send(.wrapperCleared)
        }

      case .wrapperCleared:
        state.phase = .revealing
        return .none

      case .revealNext:
        guard state.phase == .revealing else { return .none }
        state.revealedCount = min(state.revealedCount + 1, state.revealOrder.count)

        if state.revealedCount == state.revealOrder.count {
          return .run { send in
            try await clock.sleep(for: .milliseconds(700))
            await send(.showSummary)
          }
        }
        return .none

      case let .revealed(upTo: count):
        guard state.phase == .revealing else { return .none }
        // Set outright rather than stepping: a flick can carry the scroll past
        // several cards at once, and the count has to follow where it landed.
        // Deliberately never reaches the summary — that is the scroll running
        // off the end of the pack, which arrives as `revealAll`.
        state.revealedCount = min(max(state.revealedCount, count), state.revealOrder.count)
        return .none

      case .revealAll:
        guard state.phase == .revealing else { return .none }
        state.revealedCount = state.revealOrder.count
        return .send(.showSummary)

      case .showSummary:
        guard state.phase != .summary else { return .none }
        state.phase = .summary
        return .none

      case .openAnotherTapped:
        return .send(.delegate(.openAnother))

      case .doneTapped:
        return .send(.delegate(.finished))

      case .delegate:
        return .none
      }
    }
  }
}

public extension PackSessionFeature {
  @ObservableState struct State: Equatable {
    public let pack: BoosterPack
    var phase: Phase = .sealed
    var revealedCount = 0

    /// Filler first, headliners last.
    let revealOrder: [PulledCard]

    public init(pack: BoosterPack) {
      self.pack = pack
      revealOrder = pack.revealOrder
    }

    var currentCard: PulledCard? {
      revealOrder[safe: revealedCount]
    }

    var revealedCards: [PulledCard] {
      Array(revealOrder.prefix(revealedCount))
    }

    var isFullyRevealed: Bool {
      revealedCount >= revealOrder.count
    }
  }

  @CasePathable enum Action: Equatable {
    /// The drag finished the tear; the wrapper starts coming apart.
    case tearCompleted
    case wrapperCleared
    case revealNext
    /// The reader scrolled onto a card; the payload is how many have now been
    /// seen, not a step.
    case revealed(upTo: Int)
    case revealAll
    case showSummary
    case openAnotherTapped
    case doneTapped
    case delegate(Delegate)

    public enum Delegate: Equatable {
      /// Roll another pack of the same product without going back to the shelf.
      case openAnother
      case finished
    }
  }
}

public extension PackSessionFeature.State {
  enum Phase: Equatable {
    /// Sealed and in the player's hands, waiting to be torn.
    case sealed
    /// Torn: the strip is flying away and the cards are coming out.
    case opening
    /// Cards being turned over one at a time.
    case revealing
    /// The whole pack laid out.
    case summary
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
