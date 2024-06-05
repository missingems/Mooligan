import SwiftUI

public struct TextView: View {
  @Binding private var text: String
  @State private var height: CGFloat = 0
  private let font: UIFont
  private let foregroundColor: UIColor
  
  public init(
    text: Binding<String>,
    font: UIFont,
    foregroundColor: UIColor
  ) {
    self._text = text
    self.font = font
    self.foregroundColor = foregroundColor
  }
  
  public var body: some View {
    _TextView(
      text: $text,
      font: font,
      foregroundColor: foregroundColor,
      textDidChange: textDidChange
    )
    .frame(height: height)
  }
  
  private func textDidChange(_ textView: UITextView) {
    self.height = textView.contentSize.height
  }
}

fileprivate struct _TextView: UIViewRepresentable {
  fileprivate typealias UIViewType = UITextView
  
  @Binding public var text: String
  private let textDidChange: (UITextView) -> Void
  private let font: UIFont
  private let foregroundColor: UIColor
  
  init(
    text: Binding<String>,
    font: UIFont,
    foregroundColor: UIColor,
    textDidChange: @escaping (UITextView) -> Void
  ) {
    self._text = text
    self.font = font
    self.foregroundColor = foregroundColor
    self.textDidChange = textDidChange
  }
  
  fileprivate func makeUIView(context: Context) -> UITextView {
    let view = UITextView()
    view.isEditable = false
    view.isScrollEnabled = true
    view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    view.delegate = context.coordinator
    view.textColor = foregroundColor
    view.font = font
    view.textContainerInset = .zero
    view.textContainer.lineFragmentPadding = 0
    return view
  }
  
  fileprivate func updateUIView(_ uiView: UITextView, context: Context) {
    uiView.text = self.text
    DispatchQueue.main.async {
      self.textDidChange(uiView)
      uiView.isScrollEnabled = false
    }
  }
  
  fileprivate func makeCoordinator() -> Coordinator {
    Coordinator(text: $text, textDidChange: textDidChange)
  }
  
  fileprivate class Coordinator: NSObject, UITextViewDelegate {
    @Binding var text: String
    let textDidChange: (UITextView) -> Void
    
    fileprivate init(text: Binding<String>, textDidChange: @escaping (UITextView) -> Void) {
      self._text = text
      self.textDidChange = textDidChange
    }
    
    fileprivate func textViewDidChange(_ textView: UITextView) {
      self.text = textView.text
      self.textDidChange(textView)
    }
  }
}
