import Nuke
import SVGView
import SwiftUI
import UIKit

public struct IconLazyImage: View {
  private let url: URL?
  private let tintColor: Color
  private let rasterSize: CGFloat

  @State private var icon: UIImage?
  // Only the colour scheme can change what a tint resolves to here; depending on the whole
  // environment re-evaluated every icon on screen whenever any environment value moved.
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) private var displayScale

  /// The box, in points, an icon is rasterized into unless a call site asks for more. Every list and
  /// widget icon is shown at 34 points or less, so this stays sharp while keeping each bitmap small
  /// (at 3x, 48 points is about 80 KB against 590 KB for the 128 points used before).
  nonisolated public static let defaultRasterSize: CGFloat = 48

  /// - Parameter rasterSize: the square box, in points, the icon is rasterized into. Pass the size
  ///   it is displayed at when that is larger than `defaultRasterSize`, or it is scaled up and blurs.
  public init(
    _ url: URL?,
    tintColor: Color = DesignComponentsAsset.accentColor.swiftUIColor,
    rasterSize: CGFloat = IconLazyImage.defaultRasterSize
  ) {
    self.url = url
    self.tintColor = tintColor
    self.rasterSize = rasterSize
    // Peeked with the default environment: close enough to key the very first frame, and `.task`
    // below corrects it against the real environment as soon as the view appears.
    _icon = State(initialValue: url.flatMap {
      IconBitmapCache.image(for: IconRequest(
        url: $0, tint: tintColor.resolve(in: EnvironmentValues()), pointSize: rasterSize
      ))
    })
  }

  private var request: IconRequest {
    var environment = EnvironmentValues()
    environment.colorScheme = colorScheme
    return IconRequest(url: url, tint: tintColor.resolve(in: environment), pointSize: rasterSize)
  }

  public var body: some View {
    Color.clear
      .overlay {
        if let icon {
          Image(uiImage: icon)
            .resizable()
            .scaledToFit()
        } else {
          // Deliberately static: an animated placeholder (the previous shimmer) redraws every frame
          // for as long as it is on screen, and dozens can be loading at once while a long set list
          // scrolls, which is exactly the sustained main-thread cost this view exists to avoid.
          Circle().fill(Color.primary.opacity(0.12))
        }
      }
      .task(id: request) {
        await load()
      }
  }

  private func load() async {
    guard let url else { return }
    let request = request

    if let cached = IconBitmapCache.image(for: request) {
      if icon !== cached { icon = cached }
      return
    }

    let started = ContinuousClock.now
    // The already-resolved colour, not `tintColor`: `ImageRenderer` draws with a default (light)
    // environment, so an asset colour with a dark variant came out in its light one on dark screens.
    let tint = request.tint
    let size = rasterSize
    let scale = displayScale
    let fetchAndRender: @MainActor @Sendable () async -> UIImage? = {
      // The async, awaitable pipeline call cancels cleanly when this task does: scrolling a set row
      // off screen used to leave its request running to completion with no way to cancel it, and a
      // fast scroll through a long list could pile up dozens of them competing for the same handful
      // of host connections — sustained, not momentary, exactly what was reported.
      let response = try? await ImagePipeline.shared.data(for: ImageRequest(url: url))
      guard
        let data = response?.0,
        let rendered = Self.render(data, tint: tint, size: size, scale: scale)
      else {
        return nil
      }
      IconBitmapCache.insert(rendered, for: request)
      return rendered
    }
    let rendered = await IconRenderTasks.image(for: request, render: fetchAndRender)
    guard let rendered, Task.isCancelled == false else { return }

    // Only an icon slow enough to have shown the placeholder fades in; a cached one just appears.
    if icon == nil, ContinuousClock.now - started > .milliseconds(150) {
      withAnimation(.smooth) { icon = rendered }
    } else {
      icon = rendered
    }
  }

  /// Rasterizes the SVG once, the same way `SVGView` itself draws it, so this pays for the
  /// mask-and-composite SwiftUI can only do with Metal on the main thread a single time per icon
  /// rather than every time a row scrolls back into view.
  @MainActor
  private static func render(_ data: Data, tint: Color.Resolved, size: CGFloat, scale: CGFloat) -> UIImage? {
    let content = Color(tint)
      .mask { SVGView(data: data) }
      .frame(width: size, height: size)
    let renderer = ImageRenderer(content: content)
    renderer.scale = scale
    return renderer.uiImage
  }
}
