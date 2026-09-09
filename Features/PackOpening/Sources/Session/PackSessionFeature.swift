import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit

/// One pack, from the moment it is asked for to the summary of what was in it.
///
/// The session owns the roll as well as the reveal. There is no shelf to roll
/// on its behalf any more — a pack is opened straight from the set it belongs
/// to — and rolling here means the download that follows can be part of the
/// same wait rather than a second one.
@Reducer public struct PackSessionFeature: Sendable {
  /// Where a tapped card goes.
  ///
  /// The session carries its own stack rather than dismissing itself and
  /// handing the card to the host. Tearing the whole pack down to look at one
  /// card read as a modal swap — the pack vanished and something else appeared
  /// — where what is wanted is a plain push you can come back from with the
  /// pack still open behind it.
  @Reducer public enum Path {
    case showCardPager(CardPagerFeature)
    case showCardDetail(CardDetailFeature)
  }

  @Dependency(\.boosterPackClient) private var client
  @Dependency(\.packImagePrefetcher) private var prefetcher
  @Dependency(\.continuousClock) private var clock
  @Dependency(\.uuid) private var uuid

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard case .preparing = state.phase else { return .none }
        return prepare(product: state.product)

      case let .packRolled(pack):
        state.pack = pack
        return .none

      case let .readinessChanged(fraction):
        state.readiness = fraction
        return .none

      case .rollFinished:
        state.isRolled = true
        return .none

      case .preparationFinished:
        guard state.pack != nil else { return .none }
        state.readiness = 1
        state.phase = .sealed
        return .none

      case let .preparationFailed(message):
        state.phase = .failed(message)
        return .none

      case .retryTapped:
        state.phase = .preparing
        state.readiness = 0
        state.isRolled = false
        return prepare(product: state.product)

      case .tearCompleted:
        guard state.phase == .sealed else { return .none }
        state.phase = .opening

        return .run { send in
          // Long enough for the wrapper to fly off before the cards take over
          // the screen.
          try await clock.sleep(for: .milliseconds(650))
          await send(.wrapperCleared)
        }

      case .wrapperCleared:
        state.phase = .revealing
        return .none

      case let .revealed(upTo: count):
        guard state.phase == .revealing else { return .none }
        // Set outright rather than stepping: a flick can carry the stack past
        // several cards at once, and the count has to follow where it landed.
        // Deliberately never reaches the summary — that is the last card being
        // thrown, which arrives as `revealAll`.
        state.revealedCount = min(max(state.revealedCount, count), state.revealOrder.count)
        return .none

      case .revealAll:
        guard state.phase == .revealing else { return .none }
        state.revealedCount = state.revealOrder.count
        return .send(.showSummary)

      case .showSummary:
        guard state.phase != .summary else { return .none }
        state.phase = .summary
        if let pack = state.pack { state.history.add(pack) }
        return .none

      case let .didSelectCard(pulled):
        guard let pack = state.pack else { return .none }
        state.path.append(.showCardPager(pack.pagerState(startingAt: pulled)))
        return .none

      case let .path(.element(_, .showCardDetail(.didSelectVariant(card, queryType)))):
        state.path.append(
          .showCardDetail(CardDetailFeature.State(card: card, queryType: queryType))
        )
        return .none

      case .path:
        return .none

      case .openAnotherTapped:
        // Reset and re-prepare in place rather than asking the host to swap a
        // fresh state in. Replacing the state left the view's identity
        // unchanged, so its `.task` never re-fired and the new pack sat at
        // nought percent for ever.
        state.pack = nil
        state.revealedCount = 0
        state.readiness = 0
        state.isRolled = false
        state.path.removeAll()
        state.phase = .preparing
        return prepare(product: state.product)

      case .doneTapped:
        return .send(.delegate(.finished))

      case .delegate:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }

  /// Rolls the pack, then holds it shut until its art has been downloaded.
  private func prepare(product: PackProduct) -> Effect<Action> {
    .run { send in
      // Rolled first, and nothing is fetched until it is: the download is for
      // the fourteen or fifteen cards that came out, not for the set.
      let pack = try await client.open(product: product, seed: uuid())
      await send(.packRolled(pack))
      await send(.rollFinished)

      await prefetcher.prefetch(pack.packImages) { fraction in
        Task { await send(.readinessChanged(fraction)) }
      }

      await send(.preparationFinished)
    } catch: { error, send in
      await send(.preparationFailed(error.localizedDescription))
    }
    .cancellable(id: CancelID.prepare, cancelInFlight: true)
  }

  private enum CancelID { case prepare }
}

public extension PackSessionFeature {
  @ObservableState struct State: Equatable {
    public let product: PackProduct
    var phase: Phase = .preparing

    /// Fraction of the pack's art already downloaded, 0...1.
    var readiness: Double = 0

    /// The cards are decided; what is left is fetching their pictures.
    var isRolled = false

    /// Nil until the roll comes back.
    var pack: BoosterPack?

    var revealedCount = 0

    /// Cards opened out of the pack, stacked over it.
    public var path = StackState<Path.State>()

    /// What this sitting has come to so far. Survives "open another", because
    /// the session is reset in place rather than rebuilt — opening ten packs
    /// back to back is one run, and the interesting number is the run's.
    public var history = History()

    public init(product: PackProduct) {
      self.product = product
    }

    /// Filler first, headliners last.
    var revealOrder: [PulledCard] { pack?.revealOrder ?? [] }

    var revealedCards: [PulledCard] {
      Array(revealOrder.prefix(revealedCount))
    }

    var isFullyRevealed: Bool {
      revealedCount >= revealOrder.count
    }
  }

  // `@Reducer` only applies this to an `Action` nested directly in the reducer;
  // ours lives in an extension, and the presentation scopes need it.
  //
  // Not `Equatable`: the stack action wraps the pushed features' own actions,
  // which do not all conform, and nothing needs to compare two of these.
  @CasePathable enum Action {
    case task
    case packRolled(BoosterPack)
    case rollFinished
    case readinessChanged(Double)
    case preparationFinished
    case preparationFailed(String)
    case retryTapped
    /// The drag finished the tear; the wrapper starts coming apart.
    case tearCompleted
    case wrapperCleared
    /// A card reached the top of the stack; the payload is how many have now
    /// been seen, not a step.
    case revealed(upTo: Int)
    case revealAll
    case showSummary
    case didSelectCard(PulledCard)
    case path(StackActionOf<Path>)
    case openAnotherTapped
    case doneTapped
    case delegate(Delegate)

    public enum Delegate: Equatable {
      case finished
    }
  }
}

public extension PackSessionFeature.State {
  /// A running tally of everything ripped without leaving the session.
  struct History: Equatable {
    public private(set) var packs = 0
    public private(set) var cards = 0
    public private(set) var value = Decimal.zero
    public private(set) var best: PulledCard?
    /// Distinct sets, because opening another from the summary can be a
    /// different product than the one before it.
    public private(set) var setCodes: Set<String> = []

    mutating func add(_ pack: BoosterPack) {
      packs += 1
      cards += pack.cards.count
      value += pack.totalValue
      setCodes.insert(pack.product.set.code.uppercased())

      if let candidate = pack.bestPull,
        best.map({ candidate.excitement > $0.excitement }) ?? true
      {
        best = candidate
      }
    }

    /// Nothing to say until a second pack makes it a run rather than a pack.
    public var isWorthShowing: Bool { packs > 1 }
  }

  enum Phase: Equatable {
    /// Rolling the pack and downloading its art.
    case preparing
    /// Ready, sealed, and in the player's hands waiting to be torn.
    case sealed
    /// Torn: the wrapper is flying away and the cards are coming out.
    case opening
    /// Cards being dealt one at a time.
    case revealing
    /// The whole pack laid out.
    case summary
    case failed(String)
  }
}

public extension PulledCard {
  /// The one image this card is ever drawn from, at every size it is drawn at.
  ///
  /// Single-sourcing it is what lets the pack prefetch exactly what will be
  /// asked for: any view that picks a different printing is a download the
  /// pack did not make and a picture that has to fade in when it arrives.
  var imageURL: URL? {
    card.getImageURL(types: [.normal, .large, .small])
  }

  /// The pulled card as the shared `CardView` draws it, so the pack's summary
  /// is the same grid of cards a set is.
  ///
  /// Falls back to the URL the pack prefetched for the handful of printings
  /// Scryfall has no `normal` image for — `DisplayableCardImage` asks for that
  /// size alone, and a cell with nothing in it would be worse than a card that
  /// cannot be turned over.
  var displayableCardImage: DisplayableCardImage? {
    if let displayable = DisplayableCardImage(card) {
      return displayable
    }

    guard let imageURL else { return nil }
    return .single(displayingImageURL: imageURL, id: card.id.uuidString)
  }
}

public extension BoosterPack {
  /// Every image the pack will ask for, in the order they will be wanted, so
  /// the first card is ready before the last one is.
  ///
  /// Exactly the cards that were pulled — never the set they came from. The
  /// pool the roll draws from is card *data* read from the local database; no
  /// picture is fetched for a card that did not make it into the pack.
  var imageURLs: [URL] {
    revealOrder.compactMap(\.imageURL)
  }

  /// The pager for a card in this pack, paged across the whole pack so the
  /// reader can swipe between what they just pulled.
  ///
  /// Deduplicated by card: a pack can hold the same printing twice, and the
  /// pager identifies its pages by card id.
  func pagerState(startingAt pulled: PulledCard) -> CardPagerFeature.State {
    var seen = Set<UUID>()
    let details = cards.compactMap { card -> CardInfo? in
      seen.insert(card.card.id).inserted ? CardInfo(card: card.card) : nil
    }

    return CardPagerFeature.State(
      cardDetails: details,
      initialSelectedCard: pulled.card,
      queryType: .querySet(
        product.set,
        SearchQuery(setCode: product.set.code, page: 1, sortMode: .name, sortDirection: .asc)
      )
    )
  }
}

extension PackSessionFeature.Path.State: Equatable {}

extension Collection {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
