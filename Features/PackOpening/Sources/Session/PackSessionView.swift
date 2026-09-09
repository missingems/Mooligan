import CardDetail
import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

/// Full-screen host for one pack: the wait, the tear, the reveal, the summary.
public struct PackSessionView: View {
  @Bindable var store: StoreOf<PackSessionFeature>

  public init(store: StoreOf<PackSessionFeature>) {
    self.store = store
  }

  private var theme: PackTheme {
    PackTheme(setCode: store.product.set.code, kind: store.product.kind)
  }

  public var body: some View {
    // The session owns its stack: a card opened out of the pack pushes over it
    // and comes back with a plain back swipe, leaving the pack where it was.
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      session
        .toolbar(.hidden, for: .navigationBar)
    } destination: { destination in
      switch destination.case {
      case let .showCardPager(value):
        CardPagerView(store: value)

      case let .showCardDetail(value):
        CardDetail.RootView(store: value)
      }
    }
  }

  private var session: some View {
    ZStack {
      backdrop

      switch store.phase {
      case .preparing:
        PackPreparingView(
          product: store.product,
          readiness: store.readiness,
          isRolled: store.isRolled,
          cardCount: store.pack?.cards.count ?? store.product.kind.cardCount
        )
          .transition(.opacity)

      case let .failed(message):
        failure(message)
          .transition(.opacity)

      case .sealed, .opening:
        if let pack = store.pack {
          PackTearView(
            pack: pack,
            isOpening: store.phase == .opening,
            onTearCompleted: { store.send(.tearCompleted) }
          )
          .transition(.opacity)
        }

      case .revealing, .summary:
        if let pack = store.pack {
          PackRevealView(
            pack: pack,
            revealedCount: store.revealedCount,
            isSummary: store.phase == .summary,
            onRevealed: { store.send(.revealed(upTo: $0)) },
            onSelect: { store.send(.didSelectCard($0)) },
            onRevealAll: { store.send(.revealAll) },
            onOpenAnother: { store.send(.openAnotherTapped) },
            onDone: { store.send(.doneTapped) },
            history: store.history
          )
          .transition(.opacity)
        }

      }
    }
    .animation(.smooth(duration: 0.45), value: store.phase)
    .preferredColorScheme(.dark)
    .task { store.send(.task) }
    .overlay(alignment: .topLeading) {
      Group {
        Button {
          store.send(.doneTapped)
        } label: {
          Image(systemName: "xmark")
            .font(.headline)
            .foregroundStyle(.white.opacity(0.75))
            .padding(10)
            .background(Color.white.opacity(0.12), in: Circle())
        }
        .padding(.leading, 16)
        .padding(.top, 8)
        .accessibilityLabel("Close")
        .accessibilityIdentifier("packOpening.close")
      }
    }
    .accessibilityIdentifier("packOpening.session")
  }

  private func failure(_ message: String) -> some View {
    ContentUnavailableView {
      Label("Couldn't open that pack", systemImage: "shippingbox")
    } description: {
      Text(message)
    } actions: {
      Button("Try Again") { store.send(.retryTapped) }
        .buttonStyle(.borderedProminent)
    }
    .accessibilityIdentifier("packOpening.failed")
  }

  /// Plain and dark, and nothing else.
  ///
  /// This was a pair of radial gradients tinted to the set, which sounded like
  /// atmosphere and looked like a smudge behind the cards. The cards are the
  /// thing worth looking at; the background's job is to stay out of their way.
  private var backdrop: some View {
    Color(white: 0.06).ignoresSafeArea()
  }
}

/// The wait while the pack is rolled and its art comes down.
///
/// Shown as the pack itself rather than a spinner: the wrapper is the thing
/// about to be torn, so it is what the wait should be spent looking at.
struct PackPreparingView: View {
  let product: PackProduct
  let readiness: Double
  let isRolled: Bool
  let cardCount: Int

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isBreathing = false

  var body: some View {
    VStack(spacing: 28) {
      Spacer()

      BoosterPackView(product: product)
        .frame(maxWidth: 240)
        .scaleEffect(isBreathing ? 1.02 : 0.98)
        .animation(
          reduceMotion
            ? nil
            : .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
          value: isBreathing
        )
        .onAppear { isBreathing = true }

      VStack(spacing: 10) {
        Text(isRolled ? "Getting the cards" : "Rolling the pack")
          .font(.headline)
          .foregroundStyle(.white.opacity(0.9))

        ProgressView(value: max(readiness, 0.04))
          .progressViewStyle(.linear)
          .tint(.white.opacity(0.9))
          .frame(maxWidth: 220)

        // Names the number so it is plain what is being fetched: the cards
        // that came out of this pack, not the set they came from.
        Text(
          isRolled
            ? "Downloading \(cardCount) cards so nothing pops in mid-reveal"
            : "Deciding what is in it"
        )
          .font(.footnote)
          .multilineTextAlignment(.center)
          .foregroundStyle(.white.opacity(0.5))
          .padding(.horizontal, 40)
      }

      Spacer()
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Getting the pack ready")
    .accessibilityValue("\(Int(readiness * 100)) percent")
    .accessibilityIdentifier("packOpening.preparing")
  }
}
