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

private final class ChartScrubRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
  var onChange: (([CGFloat]) -> Void)?

  private static let slop: CGFloat = 5.0

  private var origin: CGPoint?
  private var tracked: [UITouch] = []

  override init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)
    delegate = self
    cancelsTouchesInView = false
    delaysTouchesBegan = false
    delaysTouchesEnded = false
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldBeRequiredToFailBy other: UIGestureRecognizer
  ) -> Bool {
    other is UIPanGestureRecognizer && other.view is UIScrollView
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)
    for touch in touches where tracked.contains(touch) == false {
      tracked.append(touch)
    }
    if origin == nil, let first = tracked.first, let view {
      origin = first.location(in: view)
    }
    evaluate()
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
    tracked.removeAll()
    origin = nil
    onChange?([])
  }

  private func evaluate() {
    guard let view else { return }
    let locations = tracked.map { $0.location(in: view) }

    guard locations.isEmpty == false else {
      state = (state == .began || state == .changed) ? .ended : .failed
      onChange?([])
      return
    }

    if locations.count >= 2 {
      state = (state == .began || state == .changed) ? .cancelled : .failed
      onChange?([])
      return
    }

    switch state {
    case .possible:
      guard let origin, let point = locations.first else { return }
      let dx = abs(point.x - origin.x)
      let dy = abs(point.y - origin.y)
      if dy > Self.slop, dy >= dx {
        state = .failed
        onChange?([])
      } else if dx > Self.slop {
        state = .began
        onChange?(locations.map(\.x))
      }

    case .began, .changed:
      state = .changed
      onChange?(locations.map(\.x))

    default:
      break
    }
  }
}
