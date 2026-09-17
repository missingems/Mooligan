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
