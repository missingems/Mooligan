import SwiftUI
import UIKit

/// The x position of a finger scrubbing the price chart, in the chart's own
/// coordinate space. Empty whenever nothing is scrubbing.
///
/// This exists because SwiftUI could not win the touch here. The chart sits in a
/// vertical scroll view nested inside the card detail's *horizontal* paging
/// scroll view, and a horizontal drag over the plot is exactly the gesture that
/// pager wants: `chartXSelection` and a plain `DragGesture` both lost, and
/// dragging across the chart flipped to the next card instead of scrubbing.
///
/// Rather than switch scrolling off — sticky state that strands the screen
/// unscrollable if a touch is ever lost — the recognizer below tells any scroll
/// view's pan, through its delegate, to wait for it to resolve. A vertical drag
/// fails it within a few points and scrolls as before; a horizontal one, or a
/// second finger, claims the touch. Nothing is left disabled afterwards, because
/// nothing was disabled.
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

/// Recognises a scrub over the chart: one finger dragged horizontally.
///
/// Fails itself the moment a drag looks vertical, or the moment a second finger
/// lands, which is what lets the page keep scrolling and pinching normally while
/// still handing horizontal drags to the chart.
private final class ChartScrubRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
  /// Active touch x positions. Empty ends the scrub.
  var onChange: (([CGFloat]) -> Void)?

  /// How far a finger must travel before the direction is taken as settled.
  /// Small enough to feel immediate, large enough that a stationary tap with a
  /// pixel of jitter does not decide it.
  private static let slop: CGFloat = 5.0

  private var origin: CGPoint?
  private var tracked: [UITouch] = []

  override init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)
    delegate = self
    // The chart draws no controls, so nothing underneath needs the touch — but
    // leaving it uncancelled keeps the rest of the row behaving normally.
    cancelsTouchesInView = false
    delaysTouchesBegan = false
    delaysTouchesEnded = false
  }

  /// Asks any scroll view's pan to wait for this recognizer to resolve.
  ///
  /// The alternative, calling `require(toFail:)` on each ancestor scroll view,
  /// writes a permanent requirement onto a recognizer this view does not own.
  /// The card pager's scroll view is shared by every page, so one requirement per
  /// chart accumulates as the reader swipes through cards — each one belonging to
  /// a page that may be long gone, and all of them gating the pan. Answering here
  /// instead is evaluated per gesture and leaves nothing behind.
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
      // Last finger up. A scrub that never started has to fail rather than end,
      // or the scroll views waiting on it stay blocked for this touch sequence.
      state = (state == .began || state == .changed) ? .ended : .failed
      onChange?([])
      return
    }

    // A second finger is never a scrub. Hand the whole sequence back rather than
    // guessing which finger was meant.
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
        // Reads as a scroll. Failing hands the touch straight back.
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

