import DesignComponents
import Networking
import SwiftUI

/// Aspect ratio of a real booster wrapper, near enough: 2.6in by 4.7in.
enum PackGeometry {
  static let widthToHeight: CGFloat = 0.55
  static let crimpDepth: CGFloat = 5
  static let crimpToothWidth: CGFloat = 8

  /// Where the tear runs, as a fraction of the wrapper's height. Just under the
  /// top crimp, which is where a real pack gives.
  static let tearBaseline: CGFloat = 0.14
}

/// The printed wrapper, with no clipping of its own.
///
/// Kept separate from `BoosterPackView` so the tear can render it twice — once
/// clipped to the strip, once to the body — and have both halves line up
/// exactly, artwork, foil and all.
struct BoosterPackArtwork: View {
  let product: PackProduct
  var theme: PackTheme

  /// The size this is being drawn at. Measured rather than read from a
  /// `GeometryReader`: the printing is sized in proportion to the wrapper, but
  /// the wrapper's size is decided by whoever is showing it — a reader here
  /// would claim that space instead of filling it.
  @State private var size: CGSize = .zero

  var body: some View {
    ZStack {
      theme.bodyGradient

      setIconWatermark(size: size)

      // Printing: a darkened band under the crimp, the set's name down the
      // middle, and the product strip at the foot of the pack.
      VStack(spacing: 0) {
        crimpBand(size: size)
        Spacer(minLength: 0)
        nameplate(size: size)
        Spacer(minLength: 0)
        productStrip(size: size)
      }
      .padding(.vertical, PackGeometry.crimpDepth + 2)

      specularSheen(size: size)
    }
    .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
  }

  // MARK: - Printing

  private func crimpBand(size: CGSize) -> some View {
    Rectangle()
      .fill(
        LinearGradient(
          colors: [.black.opacity(0.35), .black.opacity(0.08)],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .frame(height: size.height * 0.085)
      .overlay {
        // Fine ridges left by the sealing die.
        HStack(spacing: 2) {
          ForEach(0..<Int(size.width / 4), id: \.self) { _ in
            Rectangle().fill(.white.opacity(0.09)).frame(width: 1)
          }
        }
      }
  }

  private func nameplate(size: CGSize) -> some View {
    VStack(spacing: size.height * 0.012) {
      Text(product.setCode)
        .font(.system(size: size.width * 0.2, weight: .black, design: .serif))
        .fontWidth(.condensed)
        .foregroundStyle(theme.inkColor)
        .shadow(color: .black.opacity(0.45), radius: 1, y: 1)

      Text(product.set.name.uppercased())
        .font(.system(size: size.width * 0.062, weight: .semibold, design: .default))
        .fontWidth(.condensed)
        .tracking(size.width * 0.012)
        .multilineTextAlignment(.center)
        .foregroundStyle(theme.inkColor.opacity(0.9))
        .padding(.horizontal, size.width * 0.08)
        .minimumScaleFactor(0.5)
        .lineLimit(3)
    }
  }

  private func productStrip(size: CGSize) -> some View {
    VStack(spacing: size.height * 0.008) {
      Capsule()
        .fill(theme.accent.opacity(0.92))
        .frame(height: size.height * 0.055)
        .overlay {
          Text(product.kind.shortTitle)
            .font(.system(size: size.width * 0.072, weight: .heavy))
            .fontWidth(.condensed)
            .tracking(size.width * 0.02)
            .foregroundStyle(.black.opacity(0.8))
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, size.width * 0.14)

      Text("\(product.kind.cardCount) MAGIC CARDS")
        .font(.system(size: size.width * 0.05, weight: .medium))
        .fontWidth(.condensed)
        .tracking(size.width * 0.008)
        .foregroundStyle(theme.inkColor.opacity(0.72))
    }
  }

  private func setIconWatermark(size: CGSize) -> some View {
    IconLazyImage(product.iconURL, tintColor: theme.inkColor.opacity(0.16))
      .frame(width: size.width * 0.78, height: size.width * 0.78)
      .blendMode(.overlay)
      .offset(y: size.height * 0.04)
  }

  /// A soft, angled band of light travelling across the plastic. The shader
  /// handles the rainbow; this is the broad highlight sitting over it.
  private func specularSheen(size: CGSize) -> some View {
    LinearGradient(
      stops: [
        .init(color: .white.opacity(0), location: 0),
        .init(color: .white.opacity(0.32), location: 0.42),
        .init(color: .white.opacity(0.5), location: 0.5),
        .init(color: .white.opacity(0.16), location: 0.58),
        .init(color: .white.opacity(0), location: 1),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .blendMode(.plusLighter)
    .blur(radius: size.width * 0.04)
    .allowsHitTesting(false)
  }
}

/// A sealed booster: the real product photograph where one exists, and the
/// drawn wrapper — crimped outline, edge light and shadow — where it doesn't.
struct BoosterPackView: View {
  let product: PackProduct
  var shadowRadius: CGFloat = 14

  @State private var art = PackWrapperArtLoader()

  private var theme: PackTheme {
    PackTheme(setCode: product.set.code, kind: product.kind)
  }

  private var crimp: CrimpedRectangle {
    CrimpedRectangle(
      toothWidth: PackGeometry.crimpToothWidth,
      toothDepth: PackGeometry.crimpDepth
    )
  }

  var body: some View {
    Group {
      if let photo = art.photo {
        // The photograph is a cut-out with its own crimped edges, so it wants
        // neither the crimp clip nor the drawn outline over the top.
        photo
          .resizable()
          .aspectRatio(contentMode: .fit)
      } else {
        drawn
      }
    }
    .shadow(color: .black.opacity(0.45), radius: shadowRadius, y: shadowRadius * 0.55)
    .task { await art.load(for: product) }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(product.set.name) \(product.kind.title)")
  }

  private var drawn: some View {
    BoosterPackArtwork(product: product, theme: theme)
      .clipShape(crimp)
      .overlay {
        crimp.stroke(
          LinearGradient(
            colors: [.white.opacity(0.55), .clear, .white.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
      }
      .aspectRatio(PackGeometry.widthToHeight, contentMode: .fit)
  }
}
