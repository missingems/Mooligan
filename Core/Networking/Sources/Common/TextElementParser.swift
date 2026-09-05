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
    
    func flushText() {
      if !currentText.isEmpty {
        elements.append(.text(currentText, isItalic: isItalic, isKeyword: isKeyword))
        currentText = ""
      }
    }
    
    for char in text {
      if char == "<" {
        flushText()
        isKeyword = true
      } else if char == ">" {
        flushText()
        isKeyword = false
      } else if char == "(" {
        flushText()
        isItalic = true
        elements.append(.text("(", isItalic: isItalic, isKeyword: isKeyword))
      } else if char == ")" {
        flushText()
        elements.append(.text(")", isItalic: isItalic, isKeyword: isKeyword))
        isItalic = false
      } else if char == "{" {
        flushText()
        insideToken = true
      } else if char == "}" && insideToken {
        insideToken = false
        elements.append(.token(currentToken))
        currentToken = ""
      } else if insideToken {
        currentToken.append(char)
      } else {
        currentText.append(char)
      }
    }
    
    flushText()
    
    return elements
  }
}
