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
    let combinedText = elements.map { element -> Text in
      switch element {
      case let .text(value, isItalic, isKeyword):
        if isKeyword && isItalic {
          return Text("[\(value)](https://google.com)")
            .font(.system(size: font.pointSize, design: .serif))
            .underline()
            .italic()
            .foregroundStyle(.secondary)
        } else if isKeyword {
          return Text("[\(value)](https://google.com)")
            .font(.system(size: font.pointSize))
            .underline()
        } else if isItalic {
          return Text(LocalizedStringKey(value))
            .font(.system(size: font.pointSize, design: .serif).italic())
            .foregroundStyle(.secondary)
        } else {
          return Text(LocalizedStringKey(value))
            .font(.system(size: font.pointSize))
        }
        
      case let .token(value):
        return getCustomImage(
          image: "{\(value.replacingOccurrences(of: "/", with: ":"))}",
          newSize: CGSize(width: font.pointSize, height: font.pointSize)
        ).font(.system(size: font.pointSize))
      }
    }.reduce(Text(""), +)
    
    return combinedText.fixedSize(horizontal: false, vertical: true)
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
    VStack(alignment: .leading, spacing: paragraphSpacing) {
      ForEach(textElements.indices, id: \.self) { index in
        build(elements: textElements[index])
      }
    }
  }
}
