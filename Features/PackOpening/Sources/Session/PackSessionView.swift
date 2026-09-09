import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

/// Full-screen host for one pack: tear, reveal, summary.
public struct PackSessionView: View {
  @Bindable var store: StoreOf<PackSessionFeature>

  public init(store: StoreOf<PackSessionFeature>) {
    self.store = store
  }

  private var theme: PackTheme {
    PackTheme(setCode: store.pack.product.set.code, kind: store.pack.product.kind)
  }

  public var body: some View {
    ZStack {
      backdrop

      switch store.phase {
      case .sealed, .opening:
        PackTearView(
          pack: store.pack,
          isOpening: store.phase == .opening,
          onTearCompleted: { store.send(.tearCompleted) }
        )
        .transition(.opacity)

      case .revealing:
        PackRevealView(
          revealOrder: store.revealOrder,
          revealedCount: store.revealedCount,
          onRevealed: { store.send(.revealed(upTo: $0)) },
          onSkip: { store.send(.revealAll) }
        )
        .transition(.opacity.combined(with: .scale(scale: 1.06)))

      case .summary:
        PackSummaryView(
          pack: store.pack,
          onOpenAnother: { store.send(.openAnotherTapped) },
          onDone: { store.send(.doneTapped) }
        )
        .background(.regularMaterial)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.smooth(duration: 0.45), value: store.phase)
    .preferredColorScheme(store.phase == .summary ? nil : .dark)
    .overlay(alignment: .topLeading) {
      if store.phase != .summary {
        Button {
          store.send(.doneTapped)
        } label: {
          Image(systemName: "xmark")
            .font(.headline)
            .foregroundStyle(.white.opacity(0.75))
            .padding(10)
            .background(.ultraThinMaterial, in: Circle())
        }
        .padding(.leading, 16)
        .padding(.top, 8)
        .accessibilityLabel("Close")
        .accessibilityIdentifier("packOpening.close")
      }
    }
  }

  /// A dark booth lit by the pack itself.
  private var backdrop: some View {
    ZStack {
      Color.black

      RadialGradient(
        colors: [theme.base.opacity(0.45), .clear],
        center: .center,
        startRadius: 0,
        endRadius: 420
      )

      RadialGradient(
        colors: [theme.accent.opacity(0.16), .clear],
        center: .topLeading,
        startRadius: 0,
        endRadius: 500
      )
    }
    .ignoresSafeArea()
  }
}
