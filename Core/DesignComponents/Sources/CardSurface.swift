import SwiftUI

public struct CardSurface: ViewModifier, Animatable, Equatable {
  public nonisolated static func == (lhs: CardSurface, rhs: CardSurface) -> Bool {
    lhs.isFoil == rhs.isFoil
      && lhs.isActive == rhs.isActive
      && lhs.pose == rhs.pose
      && lhs.intensity == rhs.intensity
  }

  private let isFoil: Bool
  private let isActive: Bool
  private let pose: CGPoint
  private var intensity: Double

  public nonisolated var animatableData: Double {
    get { intensity }
    set { intensity = newValue }
  }
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  public init(isFoil: Bool, isActive: Bool = true, pose: CGPoint = .zero, intensity: Double = 1) {
    self.isFoil = isFoil
    self.isActive = isActive
    self.pose = pose
    self.intensity = intensity
  }

  public func body(content: Content) -> some View {
    let isTracking = isActive && scenePhase == .active && reduceMotion == false
    let tilt = isTracking ? DeviceTilt.shared.offset : .zero
    let light = CGPoint(x: tilt.x + pose.x / 40, y: tilt.y + pose.y / 40)

    surface(content, light: light)
      .task(id: isTracking) {
        guard isTracking else { return }
        await DeviceTilt.shared.track()
      }
  }

  @ViewBuilder private func surface(_ content: Content, light: CGPoint) -> some View {
    if isFoil {
      content.visualEffect { view, geometry in
        view.colorEffect(
          // The original foil, untouched, with both directions of tilt feeding its one sweep, so the
          // bands, the streak and the crinkle all move together at one pace. Tilt fed into each of them
          // separately set them moving at different rates and the foil read as busy.
          ShaderLibrary.designComponents.holographicFoil(
            .float2(geometry.size),
            .float((light.x * 1.6 + light.y * 1.0) / 0.09),
            .float(0.2 * intensity)
          )
        )
      }
    } else {
      content.overlay {
        Rectangle()
          .visualEffect { view, geometry in
            view.colorEffect(
              ShaderLibrary.designComponents.cardSheen(.float2(geometry.size), .float2(light))
            )
          }
          .compositingGroup()
          .blendMode(.screen)
          .opacity(intensity)
          .allowsHitTesting(false)
      }
    }
  }
}
