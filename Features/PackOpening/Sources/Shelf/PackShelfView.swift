import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

/// The shelf: a plain, two-column grid of packs to pick from — the same shape
/// as the card-search grid elsewhere in the app, rather than a themed scene.
struct PackShelfView: View {
  @Bindable var store: StoreOf<PackOpeningFeature>

  /// Namespace for the zoom transition out of the tapped slot.
  let dispenseNamespace: Namespace.ID

  private var columns: [GridItem] {
    [GridItem](repeating: GridItem(spacing: 12, alignment: .top), count: 2)
  }

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 20) {
        if case .data = store.mode {
          ForEach(store.visibleProducts) { product in
            PackSlotView(
              product: product,
              isDispensing: store.dispensingProductID == product.id
            ) {
              store.send(.didSelectProduct(product))
            }
            .matchedTransitionSource(id: product.id, in: dispenseNamespace)
          }
        }
      }
      .padding(.horizontal, systemHorizontalMargin)
      .padding(.top, 8)
      .padding(.bottom, 24)
    }
    .safeAreaBar(edge: .top) {
      kindFilter
        .padding(.horizontal, systemHorizontalMargin)
        .padding(.bottom, 10)
    }
    .background(DesignComponentsAsset.backgroundColor.swiftUIColor.ignoresSafeArea())
    .overlay {
      switch store.mode {
      case .loading:
        PackStatusView(status: .loading)

      case let .error(message):
        PackStatusView(status: .error(message)) { store.send(.retry) }

      case .data:
        if store.visibleProducts.isEmpty {
          PackStatusView(status: .empty)
        }
      }
    }
    .searchable(
      text: $store.query,
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: Text("Search sets")
    )
  }

  private var kindFilter: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        FilterChip(
          title: String(localized: "All"),
          isSelected: store.kindFilter == nil
        ) {
          $store.kindFilter.wrappedValue = nil
        }

        ForEach(BoosterPackKind.allCases) { kind in
          FilterChip(
            title: kind.title,
            isSelected: store.kindFilter == kind
          ) {
            $store.kindFilter.wrappedValue = store.kindFilter == kind ? nil : kind
          }
        }
      }
    }
    .scrollIndicators(.hidden)
    .scrollClipDisabled()
  }
}

private struct FilterChip: View {
  let title: String
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      Text(title)
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background {
          Capsule()
            .fill(
              isSelected
                ? AnyShapeStyle(DesignComponentsAsset.accentColor.swiftUIColor)
                : AnyShapeStyle(Color.primary.opacity(0.06))
            )
        }
        // The accent asset is near-white in dark mode and dark in light mode,
        // so the selected label has to invert with it rather than being a fixed
        // white — which was white-on-white in the dark.
        .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary.opacity(0.75))
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    .accessibilityIdentifier("packOpening.filter.\(title)")
  }
}

/// Loading, empty and error states.
struct PackStatusView: View {
  enum Status: Equatable {
    case loading
    case empty
    case error(String)
  }

  let status: Status
  var onRetry: (() -> Void)?

  var body: some View {
    VStack(spacing: 12) {
      switch status {
      case .loading:
        ProgressView()

      case .empty:
        Image(systemName: "shippingbox")
          .font(.largeTitle)
          .foregroundStyle(.secondary)
        Text("No packs found")
          .font(.headline)
        Text("No sets match that search.")
          .font(.footnote)
          .foregroundStyle(.secondary)

      case let .error(message):
        Image(systemName: "exclamationmark.triangle")
          .font(.largeTitle)
          .foregroundStyle(.secondary)
        Text("Something went wrong")
          .font(.headline)
        Text(message)
          .font(.footnote)
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 32)

        if let onRetry {
          Button("Try Again", action: onRetry)
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .accessibilityIdentifier("packOpening.status")
  }
}
