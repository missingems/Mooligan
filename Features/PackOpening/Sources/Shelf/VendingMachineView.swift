import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

/// The machine: shelves of packs behind glass.
struct VendingMachineView: View {
  @Bindable var store: StoreOf<PackOpeningFeature>

  /// Namespace for the zoom transition out of the tapped slot.
  let dispenseNamespace: Namespace.ID

  /// Horizontal room the cabinet keeps for its side pillars.
  private static let cabinetInset: CGFloat = 18

  var body: some View {
    GeometryReader { proxy in
      let slotWidth = slotWidth(in: proxy.size.width)

      ZStack {
        MachineInterior()

        ScrollView {
          LazyVStack(spacing: 0, pinnedViews: []) {
            MachineMarquee(
              title: String(localized: "BOOSTER BAR"),
              subtitle: String(localized: "PICK A PACK · TEAR IT OPEN")
            )
            .padding(.horizontal, Self.cabinetInset)
            .padding(.bottom, 18)

            kindFilter
              .padding(.horizontal, Self.cabinetInset)
              .padding(.bottom, 20)

            switch store.mode {
            case .loading:
              MachineStatusView(status: .loading)
                .padding(.top, 60)

            case let .error(message):
              MachineStatusView(status: .error(message)) { store.send(.retry) }
                .padding(.top, 60)

            case .data:
              if store.shelves.isEmpty {
                MachineStatusView(status: .empty)
                  .padding(.top, 60)
              } else {
                ForEach(store.shelves) { shelf in
                  shelfRow(shelf, slotWidth: slotWidth)
                }
              }
            }
          }
          .padding(.top, 8)
          .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)

        MachineGlass()
      }
    }
    .searchable(
      text: $store.query,
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: Text("Search sets")
    )
    .toolbarBackground(.hidden, for: .navigationBar)
  }

  /// Three slots plus the gaps between them, inside the cabinet pillars.
  private func slotWidth(in totalWidth: CGFloat) -> CGFloat {
    let spacing: CGFloat = 12
    let available = totalWidth - Self.cabinetInset * 2 - spacing * CGFloat(PackShelf.slotsPerShelf - 1)
    return max(60, available / CGFloat(PackShelf.slotsPerShelf))
  }

  private func shelfRow(_ shelf: PackShelf, slotWidth: CGFloat) -> some View {
    VStack(spacing: 0) {
      HStack(alignment: .bottom, spacing: 12) {
        ForEach(shelf.products) { product in
          PackSlotView(
            product: product,
            width: slotWidth,
            isDispensing: store.dispensingProductID == product.id
          ) {
            store.send(.didSelectProduct(product))
          }
          .matchedTransitionSource(id: product.id, in: dispenseNamespace)
        }

        // Keep a short last shelf left-aligned rather than centred.
        if shelf.products.count < PackShelf.slotsPerShelf {
          ForEach(shelf.products.count..<PackShelf.slotsPerShelf, id: \.self) { _ in
            Color.clear.frame(width: slotWidth, height: 1)
          }
        }
      }
      .padding(.horizontal, Self.cabinetInset)

      ShelfBoard()
        .padding(.top, 2)
    }
    .padding(.bottom, 18)
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
            .fill(isSelected ? VendingMachineChrome.neon.opacity(0.22) : Color.white.opacity(0.06))
            .overlay {
              Capsule().strokeBorder(
                isSelected ? VendingMachineChrome.neon.opacity(0.7) : Color.white.opacity(0.12),
                lineWidth: 1
              )
            }
        }
        .foregroundStyle(isSelected ? VendingMachineChrome.neon : Color.white.opacity(0.7))
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    .accessibilityIdentifier("packOpening.filter.\(title)")
  }
}

/// Loading, empty and error states, dressed as machine signage.
struct MachineStatusView: View {
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
          .tint(VendingMachineChrome.neon)
        Text("Stocking the machine…")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.6))

      case .empty:
        Image(systemName: "shippingbox")
          .font(.largeTitle)
          .foregroundStyle(.white.opacity(0.4))
        Text("Sold out")
          .font(.headline)
          .foregroundStyle(.white.opacity(0.8))
        Text("No sets match that search.")
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.5))

      case let .error(message):
        Image(systemName: "exclamationmark.triangle")
          .font(.largeTitle)
          .foregroundStyle(.orange.opacity(0.8))
        Text("Out of order")
          .font(.headline)
          .foregroundStyle(.white.opacity(0.85))
        Text(message)
          .font(.footnote)
          .multilineTextAlignment(.center)
          .foregroundStyle(.white.opacity(0.55))
          .padding(.horizontal, 32)

        if let onRetry {
          Button("Try Again", action: onRetry)
            .buttonStyle(.bordered)
            .tint(VendingMachineChrome.neon)
            .padding(.top, 4)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .accessibilityIdentifier("packOpening.status")
  }
}
