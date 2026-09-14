import SwiftUI
import UIKit

struct ChartTouchReader: UIViewRepresentable {
  var onChange: ([CGFloat]) -> Void

  func makeUIView(context: Context) -> TouchView {
    let view = TouchView()
    view.onChange = onChange
    return view
  }

  func updateUIView(_ uiView: TouchView, context: Context) {
    uiView.onChange = onChange
  }

  func sizeThatFits(_ proposal: ProposedViewSize, uiView: TouchView, context: Context) -> CGSize? {
    CGSize(width: proposal.width ?? 0.0, height: proposal.height ?? 0.0)
  }

  static func dismantleUIView(_ uiView: TouchView, coordinator: ()) {
    uiView.onChange = nil
  }

  final class TouchView: UIView {
    var onChange: (([CGFloat]) -> Void)?

    private lazy var recognizer: ChartScrubRecognizer = {
      let recognizer = ChartScrubRecognizer()
      recognizer.onChange = { [weak self] points in self?.onChange?(points) }
      return recognizer
    }()

    override init(frame: CGRect) {
      super.init(frame: frame)
      backgroundColor = .clear
      isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      guard window != nil, recognizer.view !== self else { return }
      addGestureRecognizer(recognizer)
    }
  }
}

struct ScrubPressRule: Equatable, Sendable {
  static let standard = ScrubPressRule(minimumPressDuration: 0.3, allowableMovement: 10.0)

  let minimumPressDuration: TimeInterval
  let allowableMovement: CGFloat

  func hasDrifted(from origin: CGPoint, to point: CGPoint) -> Bool {
    hypot(point.x - origin.x, point.y - origin.y) > allowableMovement
  }
}

private final class ChartScrubRecognizer: UIGestureRecognizer {
  var onChange: (([CGFloat]) -> Void)?

  private let rule = ScrubPressRule.standard
  private var origin: CGPoint?
  private var tracked: [UITouch] = []
  private var pressTimer: Timer?

  override init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)
    cancelsTouchesInView = false
    delaysTouchesBegan = false
    delaysTouchesEnded = false
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)
    for touch in touches where tracked.contains(touch) == false {
      tracked.append(touch)
    }

    guard state == .possible else {
      evaluate()
      return
    }
    guard tracked.count == 1, let view, let first = tracked.first else {
      fail()
      return
    }

    origin = first.location(in: view)
    pressTimer?.invalidate()
    pressTimer = Timer.scheduledTimer(withTimeInterval: rule.minimumPressDuration, repeats: false) { [weak self] _ in
      MainActor.assumeIsolated { self?.activate() }
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    evaluate()
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesEnded(touches, with: event)
    tracked.removeAll { touches.contains($0) }
    evaluate()
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesCancelled(touches, with: event)
    tracked.removeAll { touches.contains($0) }
    evaluate()
  }

  override func reset() {
    super.reset()
    pressTimer?.invalidate()
    pressTimer = nil
    tracked.removeAll()
    origin = nil
    onChange?([])
  }

  private func activate() {
    pressTimer = nil
    guard state == .possible, tracked.count == 1, let view, let first = tracked.first else { return }
    state = .began
    onChange?([first.location(in: view).x])
  }

  private func fail() {
    pressTimer?.invalidate()
    pressTimer = nil
    state = .failed
    onChange?([])
  }

  private func evaluate() {
    guard let view else { return }
    let locations = tracked.map { $0.location(in: view) }

    switch state {
    case .possible:
      guard let origin, let point = locations.first, locations.count == 1 else {
        fail()
        return
      }
      if rule.hasDrifted(from: origin, to: point) {
        fail()
      }

    case .began, .changed:
      if locations.isEmpty {
        state = .ended
        onChange?([])
      } else if locations.count >= 2 {
        state = .cancelled
        onChange?([])
      } else {
        state = .changed
        onChange?(locations.map(\.x))
      }

    default:
      break
    }
  }
}
