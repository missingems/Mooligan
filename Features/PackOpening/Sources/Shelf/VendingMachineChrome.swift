import SwiftUI

/// The cabinet the packs sit in.
///
/// Everything here is decorative: it draws behind and in front of the shelves
/// and never takes a touch, so tapping "through" the glass hits the pack.
enum VendingMachineChrome {
  static let cabinet = Color(red: 0.07, green: 0.075, blue: 0.09)
  static let cabinetEdge = Color(red: 0.16, green: 0.17, blue: 0.2)
  static let neon = Color(red: 0.36, green: 0.86, blue: 1)
}

/// Painted steel behind the shelves, with the interior light falling off toward
/// the bottom of the cabinet.
struct MachineInterior: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          VendingMachineChrome.cabinet,
          Color(red: 0.11, green: 0.12, blue: 0.15),
          VendingMachineChrome.cabinet,
        ],
        startPoint: .top,
        endPoint: .bottom
      )

      // Light spilling from the top of the cabinet.
      RadialGradient(
        colors: [VendingMachineChrome.neon.opacity(0.16), .clear],
        center: .top,
        startRadius: 0,
        endRadius: 420
      )
    }
    .ignoresSafeArea()
  }
}

/// The lit sign across the top of the machine.
struct MachineMarquee: View {
  let title: String
  let subtitle: String

  var body: some View {
    VStack(spacing: 3) {
      Text(title)
        .font(.system(size: 22, weight: .black, design: .rounded))
        .tracking(3)
        .foregroundStyle(.white)
        .shadow(color: VendingMachineChrome.neon.opacity(0.9), radius: 10)
        .shadow(color: VendingMachineChrome.neon.opacity(0.5), radius: 22)

      Text(subtitle)
        .font(.caption2.weight(.semibold))
        .tracking(1.6)
        .foregroundStyle(.white.opacity(0.55))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Color.black.opacity(0.55))
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
              LinearGradient(
                colors: [VendingMachineChrome.neon.opacity(0.8), VendingMachineChrome.neon.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 1.5
            )
        }
    }
    .accessibilityElement(children: .combine)
  }
}

/// The board a row of packs stands on: a lit front lip, a dark tray, and the
/// shadow the packs cast onto it.
struct ShelfBoard: View {
  var body: some View {
    VStack(spacing: 0) {
      // Front lip, catching the cabinet light.
      Rectangle()
        .fill(
          LinearGradient(
            colors: [
              Color(white: 0.42),
              Color(white: 0.22),
              Color(white: 0.34),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(height: 7)
        .overlay(alignment: .top) {
          Rectangle()
            .fill(VendingMachineChrome.neon.opacity(0.35))
            .frame(height: 1)
            .blur(radius: 0.5)
        }

      // The underside, receding into the cabinet.
      LinearGradient(
        colors: [.black.opacity(0.55), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 22)
    }
    .accessibilityHidden(true)
  }
}

/// The glass door. A broad diagonal reflection plus a vignette, drawn over
/// everything and hit-testing disabled.
struct MachineGlass: View {
  var body: some View {
    ZStack {
      LinearGradient(
        stops: [
          .init(color: .white.opacity(0.1), location: 0),
          .init(color: .white.opacity(0.02), location: 0.32),
          .init(color: .white.opacity(0.075), location: 0.42),
          .init(color: .clear, location: 0.55),
          .init(color: .white.opacity(0.03), location: 1),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .blendMode(.plusLighter)

      RadialGradient(
        colors: [.clear, .black.opacity(0.4)],
        center: .center,
        startRadius: 180,
        endRadius: 620
      )
    }
    .ignoresSafeArea()
    .allowsHitTesting(false)
  }
}
