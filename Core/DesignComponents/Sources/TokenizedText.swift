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
    // Pre-calculate font configurations to avoid repeated system calls
    let baseFont = Font.system(size: font.pointSize)
    let serifFont = Font.system(size: font.pointSize, design: .serif)
    let italicSerifFont = serifFont.italic()
    
    // Use array with initial capacity to avoid reallocation
    var textComponents: [Text] = []
    textComponents.reserveCapacity(elements.count)
    
    // Single pass through elements
    for element in elements {
      let textComponent: Text
      
      switch element {
      case let .text(value, isItalic, isKeyword):
        switch (isKeyword, isItalic) {
        case (true, true):
          textComponent = Text("[\(value)](https://google.com)")
            .font(italicSerifFont)
            .underline()
            .foregroundStyle(.secondary)
          
        case (true, false):
          textComponent = Text("[\(value)](https://google.com)")
            .font(baseFont)
            .underline()
          
        case (false, true):
          textComponent = Text(LocalizedStringKey(value))
            .font(italicSerifFont)
            .foregroundStyle(.secondary)
          
        case (false, false):
          textComponent = Text(LocalizedStringKey(value))
            .font(baseFont)
        }
        
      case let .token(value):
        // Cache the processed token string if tokens repeat frequently
        let processedToken = value.replacingOccurrences(of: "/", with: ":")
        textComponent = getCustomImage(
          image: "{\(processedToken)}",
          newSize: CGSize(width: font.pointSize / 1.25, height: font.pointSize / 1.25)
        )
        .font(baseFont)
      }
      
      textComponents.append(textComponent)
    }
    
    // More efficient reduction using reduce(into:) which mutates in-place
    let combinedText = textComponents.reduce(into: Text("")) { result, text in
      result = result + text
    }
    
    return combinedText.fixedSize(horizontal: false, vertical: true)
  }
  
  private func getCustomImage(image: String, newSize: CGSize) -> Text {
    if let image = UIImage(named: image, in: DesignComponentsResources.bundle, with: nil),
       let newImage = convertImageToNewFrame(image: image, newFrameSize: newSize) {
      return Text(Image(uiImage: newImage).resizable())
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
