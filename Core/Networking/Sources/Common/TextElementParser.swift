public indirect enum TextElement: Hashable, Sendable, Equatable {
  case text(String, isItalic: Bool, isKeyword: Bool)
  case token(String)
}

public enum TextElementParser {
  public static func parse(_ text: String) -> [TextElement] {
    var elements: [TextElement] = []
    var isKeyword = false
    var isItalic = false
    var currentText = ""
    var currentToken = ""
    var insideToken = false
    
    for char in text {
      if char == "<" {
        isKeyword = true
      } else if char == ">" {
        isKeyword = false
      } else if char == "(" {
        isItalic = true
        elements.append(.text("(", isItalic: isItalic, isKeyword: isKeyword))
      } else if char == ")" {
        elements.append(.text(")", isItalic: isItalic, isKeyword: isKeyword))
        isItalic = false
      } else if char == "{" {
        if !currentText.isEmpty {
          elements.append(.text(currentText, isItalic: isItalic, isKeyword: isKeyword))
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
        elements.append(.text("\(char)", isItalic: isItalic, isKeyword: isKeyword))
      }
    }
    
    if !currentText.isEmpty {
      elements.append(.text(currentText, isItalic: isItalic, isKeyword: isKeyword))
    }
    
    return elements
  }
}
