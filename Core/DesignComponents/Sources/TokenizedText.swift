import SwiftUI

public struct TokenizedText: View {
  private var text: String
  private var font: UIFont
  private let paragraphSpacing: CGFloat
  
  public init(
    text: String,
    font: UIFont,
    paragraphSpacing: CGFloat
  ) {
    self.text = text
    self.font = font
    self.paragraphSpacing = paragraphSpacing
  }
  
  @ViewBuilder func build() -> some View {
    VStack(alignment: .leading, spacing: paragraphSpacing) {
      let substrings = text.split(separator: "\n")
      ForEach(substrings.indices, id: \.self) { index in
        let element = substrings[index]
        build(elements: parseText(String(element)))
      }
    }
  }
  
  // Parses the given text and returns an array of either text or token identifiers
  private func parseText(_ text: String) -> [TextElement] {
    var elements: [TextElement] = []
    var isItalic = false
    var currentText = ""
    var currentToken = ""
    var insideToken = false
    
    for char in text {
      if char == "(" {
        isItalic = true
        elements.append(.text("(", isItalic: isItalic))
      } else if char == ")" {
        elements.append(.text(")", isItalic: isItalic))
        isItalic = false
      } else if char == "{" {
        if !currentText.isEmpty {
          elements.append(.text(currentText, isItalic: isItalic))
          currentText = ""
        }
        insideToken = true
      } else if char == "}" && insideToken {
        insideToken = false
        elements.append(.token(currentToken))
        currentToken = ""
      } else if insideToken {
        currentToken.append(char)
      } else {
        elements.append(.text("\(char)", isItalic: isItalic))
      }
    }
    
    if !currentText.isEmpty {
      elements.append(.text(currentText, isItalic: isItalic))
    }
    
    return elements
  }
  
  private func build(elements: [TextElement]) -> some View {
    var text: Text?
    
    elements.forEach { element in
      switch element {
      case let .text(value, isItalic):
        if isItalic {
          if text == nil {
            text = Text(value).font(Font.system(size: self.font.pointSize, design: .serif).italic()).foregroundStyle(.secondary)
          } else if let _text = text {
            text = _text + Text(value).font(Font.system(size: self.font.pointSize, design: .serif).italic()).foregroundStyle(.secondary)
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
      return Text(Image(uiImage: newImage).resizable()).baselineOffset(-2)
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
    build()
  }
  
  indirect enum TextElement: Hashable {
    case text(String, isItalic: Bool)
    case token(String)
  }
}
