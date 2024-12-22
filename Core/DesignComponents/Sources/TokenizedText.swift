import Networking
import SwiftUI

public struct TokenizedText: View {
  private var textElements: [[TextElement]]
  private var font: UIFont
  private let paragraphSpacing: CGFloat
  
  public init(
    textElements: [[TextElement]],
    font: UIFont,
    paragraphSpacing: CGFloat
  ) {
    self.textElements = textElements
    self.font = font
    self.paragraphSpacing = paragraphSpacing
  }
  
  private func build(elements: [TextElement]) -> some View {
    var text: Text?
    
    elements.forEach { element in
      switch element {
      case let .text(value, isItalic, isKeyword):
        if isKeyword && isItalic {
          if text == nil {
            text = Text("[\(value)](https://google.com)").font(Font.system(size: self.font.pointSize, design: .serif)).underline().italic().foregroundStyle(.secondary)
          } else if let _text = text {
            text = _text + Text("[\(value)](https://google.com)").font(Font.system(size: self.font.pointSize, design: .serif)).underline().italic().foregroundStyle(.secondary)
          }
        } else if isKeyword {
          if text == nil {
            text = Text("[\(value)](https://google.com)").font(Font.system(size: self.font.pointSize)).underline()
          } else if let _text = text {
            text = _text + Text("[\(value)](https://google.com)").font(Font.system(size: self.font.pointSize)).underline()
          }
        } else if isItalic {
          if text == nil {
            text = Text(LocalizedStringKey(value)).font(Font.system(size: self.font.pointSize, design: .serif).italic()).foregroundStyle(.secondary)
          } else if let _text = text {
            text = _text + Text(LocalizedStringKey(value)).font(Font.system(size: self.font.pointSize, design: .serif).italic()).foregroundStyle(.secondary)
          }
        } else {
          if text == nil {
            text = Text(LocalizedStringKey(value)).font(Font.system(size: self.font.pointSize))
          } else if let _text = text {
            text = _text + Text(LocalizedStringKey(value)).font(Font.system(size: self.font.pointSize))
          }
        }
        
      case let .token(value):
        if text == nil {
          text = getCustomImage(image: "{\(value.replacingOccurrences(of: "/", with: ":"))}", newSize: CGSize(width: font.pointSize, height: font.pointSize)).font(Font.system(size: self.font.pointSize))
        } else if let _text = text {
          text = _text + getCustomImage(image: "{\(value.replacingOccurrences(of: "/", with: ":"))}", newSize: CGSize(width: font.pointSize, height: font.pointSize)).font(Font.system(size: self.font.pointSize))
        }
      }
    }
    
    return (text ?? Text("")).fixedSize(horizontal: false, vertical: true)
  }
  
  private func getCustomImage(image: String, newSize: CGSize) -> Text {
    if let image = UIImage(named: image, in: DesignComponentsResources.bundle, with: nil),
       let newImage = convertImageToNewFrame(image: image, newFrameSize: newSize) {
      return Text(Image(uiImage: newImage).resizable()).baselineOffset(-3)
    } else {
      return Text("")
    }
  }
  
  func convertImageToNewFrame(image: UIImage, newFrameSize: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(newFrameSize, false, 0.0)
    image.draw(in: CGRect(origin: .zero, size: newFrameSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
  }
  
  public var body: some View {
    LazyVStack(alignment: .leading, spacing: paragraphSpacing) {
      ForEach(textElements.indices, id: \.self) { index in
        build(elements: textElements[index])
      }
    }
  }
}
